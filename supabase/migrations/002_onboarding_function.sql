-- ── ONBOARDING FUNCTION ─────────────────────────────────────
-- This function allows a newly signed up user (with no organisation)
-- to create their initial organisation, branch, and user profile.
CREATE OR REPLACE FUNCTION setup_business(
  org_name TEXT,
  branch_name TEXT,
  owner_full_name TEXT
) RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  new_org_id UUID;
  new_branch_id UUID;
  user_id UUID;
BEGIN
  user_id := auth.uid();
  IF user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- Ensure user doesn't already have a profile
  IF EXISTS (SELECT 1 FROM user_profiles WHERE id = user_id) THEN
    RAISE EXCEPTION 'User already has a profile';
  END IF;

  -- Create organisation
  INSERT INTO organisations (name) VALUES (org_name) RETURNING id INTO new_org_id;

  -- Create branch
  INSERT INTO branches (organisation_id, name) VALUES (new_org_id, branch_name) RETURNING id INTO new_branch_id;

  -- Create user profile
  INSERT INTO user_profiles (id, organisation_id, full_name, role)
  VALUES (user_id, new_org_id, owner_full_name, 'owner');

  -- Create user branch access
  INSERT INTO user_branch_access (user_id, branch_id)
  VALUES (user_id, new_branch_id);

  RETURN jsonb_build_object(
    'organisation_id', new_org_id,
    'branch_id', new_branch_id
  );
END;
$$;
