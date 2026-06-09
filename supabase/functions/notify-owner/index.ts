import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { initializeApp, cert } from "npm:firebase-admin/app";
import { getMessaging } from "npm:firebase-admin/messaging";

// Initialize Firebase Admin (Only once per isolate)
const serviceAccountKeyStr = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_KEY");
if (serviceAccountKeyStr) {
  try {
    const serviceAccount = JSON.parse(serviceAccountKeyStr);
    initializeApp({
      credential: cert(serviceAccount),
    });
  } catch (err) {
    console.error("Failed to initialize Firebase Admin:", err);
  }
}

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const supabase = createClient(supabaseUrl, supabaseKey);

serve(async (req) => {
  try {
    const payload = await req.json();
    console.log("Received webhook payload:", payload);

    const { type, table, record, old_record } = payload;
    let title = "";
    let body = "";

    // 1. Determine the message based on the event
    if (table === "sales") {
      if (type === "INSERT" && record.total >= 100000) {
        // High value sale (> KES 1,000)
        title = "New Sale!";
        body = `A new sale of KES ${(record.total / 100).toLocaleString()} was just made.`;
      } else if (type === "UPDATE" && record.is_voided === true && (!old_record || old_record.is_voided !== true)) {
        title = "Sale Voided";
        body = `A sale of KES ${(record.total / 100).toLocaleString()} was just voided.`;
      } else {
        return new Response("Not a notifyable sale event", { status: 200 });
      }
    } else if (table === "open_tabs") {
      if (type === "INSERT") {
        title = "New Tab Opened";
        body = `A new tab was opened for ${record.name || 'a customer'}.`;
      } else if (type === "UPDATE" && record.is_open === false && (!old_record || old_record.is_open !== false)) {
        title = "Tab Closed";
        body = `The tab for ${record.name || 'a customer'} was closed.`;
      } else {
        return new Response("Not a notifyable tab event", { status: 200 });
      }
    } else if (table === "stock_levels") {
      if (type === "UPDATE" && record.quantity <= record.reorder_level) {
        // Only notify if it just crossed the threshold to avoid spam on every decrement below reorder level
        if (old_record && old_record.quantity > record.reorder_level) {
          title = "Low Stock Alert";
          body = `A product has reached its reorder level (${record.quantity} left).`;
        } else {
          return new Response("Already below reorder level", { status: 200 });
        }
      } else {
         return new Response("Stock is fine", { status: 200 });
      }
    } else {
      return new Response("Unknown table", { status: 400 });
    }

    // 2. Fetch owner FCM tokens
    const { data: owners, error: userErr } = await supabase
      .from('user_profiles')
      .select('id')
      .eq('role', 'owner');
      
    if (userErr || !owners || owners.length === 0) {
      console.log("No owners found or error:", userErr);
      return new Response("No owners to notify", { status: 200 });
    }

    const ownerIds = owners.map(o => o.id);

    const { data: devices, error: deviceErr } = await supabase
      .from('user_devices')
      .select('fcm_token')
      .in('user_id', ownerIds);

    if (deviceErr || !devices || devices.length === 0) {
      console.log("No devices found for owners");
      return new Response("No devices found", { status: 200 });
    }

    const tokens = devices.map(d => d.fcm_token);

    // 3. Send via Firebase Admin
    if (tokens.length > 0 && serviceAccountKeyStr) {
      const response = await getMessaging().sendEachForMulticast({
        tokens: tokens,
        notification: {
          title: title,
          body: body,
        },
        android: {
          priority: 'high',
          notification: {
            channelId: 'paps_n_pops_alerts',
          }
        }
      });
      console.log("Successfully sent messages:", response.successCount);
    } else {
      console.log("No tokens or missing Firebase service account key");
    }

    return new Response(JSON.stringify({ success: true, title, body }), {
      headers: { "Content-Type": "application/json" },
      status: 200,
    });
  } catch (error) {
    console.error("Error processing webhook:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { "Content-Type": "application/json" },
      status: 500,
    });
  }
});
