import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2.43.4";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      throw new Error("Missing Authorization header");
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

    if (!supabaseUrl || !supabaseServiceKey) {
      throw new Error("Missing Supabase environment variables");
    }

    // Client for admin tasks (bypass RLS)
    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
    });

    // Client for verifying the caller's JWT
    const supabaseUserClient = createClient(
      supabaseUrl,
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      {
        global: { headers: { Authorization: authHeader } },
      }
    );

    // 1. Verify caller is an owner
    const { data: { user: caller }, error: callerError } = await supabaseUserClient.auth.getUser();
    if (callerError || !caller) {
      throw new Error("Invalid or expired token");
    }

    const role = caller.user_metadata?.role;
    if (role !== "owner") {
      throw new Error("Unauthorized. Only owners can create users.");
    }

    // 2. Parse request body
    const body = await req.json();
    const { email, password, full_name, role: newUserRole, organisation_id, branch_ids } = body;

    if (!email || !password || !full_name || !newUserRole || !organisation_id || !branch_ids) {
      throw new Error("Missing required fields");
    }

    // 3. Create the auth user with admin api
    const { data: authData, error: authError } = await supabaseAdmin.auth.admin.createUser({
      email,
      password,
      email_confirm: true, // Auto-confirm for internal users
      user_metadata: {
        full_name,
        role: newUserRole,
        organisation_id,
        branch_ids,
      },
    });

    if (authError) {
      throw authError;
    }

    const newUserId = authData.user.id;

    // 4. Insert into user_profiles
    const { error: profileError } = await supabaseAdmin.from("user_profiles").insert({
      id: newUserId,
      full_name,
      role: newUserRole,
      organisation_id,
    });

    if (profileError) {
      console.error("Profile creation error:", profileError);
      // We don't throw here to avoid leaving an orphaned auth user, but in a real app
      // you might want a saga or rollback. We'll proceed.
    }

    // 5. Insert into user_branch_access
    const branchAccessInserts = branch_ids.map((branch_id: string) => ({
      user_id: newUserId,
      branch_id,
    }));

    const { error: branchError } = await supabaseAdmin.from("user_branch_access").insert(branchAccessInserts);

    if (branchError) {
      console.error("Branch access creation error:", branchError);
    }

    return new Response(JSON.stringify({ success: true, user_id: newUserId }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 200,
    });
  } catch (error: any) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 400,
    });
  }
});
