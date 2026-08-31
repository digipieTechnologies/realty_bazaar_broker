# Supabase Account & Multi-Environment Migration Guide

This step-by-step guide helps you switch to your new Supabase account and deploy both **Development** (`realty-bazaar-dev`) and **Production** (`realty-bazaar-prod`) environments seamlessly.

---

## 1. Create Projects in your New Supabase Account
1. Log in to your new Supabase account at [supabase.com/dashboard](https://supabase.com/dashboard).
2. Create **Project 1**: `realty-bazaar-dev` (Development).
3. Create **Project 2**: `realty-bazaar-prod` (Production).

---

## 2. Apply Migrations to Both Projects

You have **two easy ways** to apply the complete database schema:

### Method A: Automated via Supabase CLI (Recommended)
Because all 50 sequential migration files exist in `supabase/migrations/`, you can push them directly:

```bash
# 1. Push to Development Project
npx supabase link --project-ref <DEV_PROJECT_REF>
npx supabase db push

# 2. Push to Production Project
npx supabase link --project-ref <PROD_PROJECT_REF>
npx supabase db push
```

---

### Method B: Via Supabase Web Dashboard SQL Editor
If you prefer running SQL scripts manually in the Supabase Dashboard:

1. **Step 1: Complete Migrations Bundle**
   - Open your project SQL Editor.
   - Run [supabase/00_complete_migrations_bundle.sql](file:///Users/zahidshaikh/Public/flutter_projects/realty_bazaar_broker/supabase/00_complete_migrations_bundle.sql) *(this consolidates all 50 database tables, triggers, enum types, RPC functions, and RLS policies in exact chronological order)*.

2. **Step 2: Storage Buckets & Policies**
   - Run [supabase/storage_setup.sql](file:///Users/zahidshaikh/Public/flutter_projects/realty_bazaar_broker/supabase/storage_setup.sql) *(creates `social_assets` and `property_media` buckets with public access policies)* on **both Dev and Prod**.

3. **Step 3: Initial Seed Data (Dev Only)**
   - Run [supabase/seed_dev.sql](file:///Users/zahidshaikh/Public/flutter_projects/realty_bazaar_broker/supabase/seed_dev.sql) on your **Development** project.

---

## 3. Deploy Edge Functions & Set Secrets

Log in to the Supabase CLI:
```bash
npx supabase login
```

### 3.1 For Development Project:
```bash
# Link dev project
npx supabase link --project-ref <DEV_PROJECT_REF>

# Deploy all Edge Functions
npx supabase functions deploy

# Set environment secrets
npx supabase secrets set \
  FB_APP_ID="<your_facebook_app_id>" \
  FB_APP_SECRET="<your_facebook_app_secret>" \
  RESEND_API_KEY="<your_resend_api_key>" \
  FCM_SERVER_KEY="<your_fcm_server_key>"
```

### 3.2 For Production Project:
```bash
# Link prod project
npx supabase link --project-ref <PROD_PROJECT_REF>

# Deploy all Edge Functions
npx supabase functions deploy

# Set environment secrets
npx supabase secrets set \
  FB_APP_ID="<your_prod_facebook_app_id>" \
  FB_APP_SECRET="<your_prod_facebook_app_secret>" \
  RESEND_API_KEY="<your_resend_api_key>" \
  FCM_SERVER_KEY="<your_fcm_server_key>"
```

---

## 4. Configure Local Environment Files

Create `.env.dev` and `.env.prod` at the root of the project (these are git-ignored):

### `.env.dev`
```properties
SUPABASE_URL=https://<dev-project-ref>.supabase.co
SUPABASE_ANON_KEY=<dev-anon-key>
ONESIGNAL_APP_ID=<your-onesignal-app-id>
ENVIRONMENT=dev
```

### `.env.prod`
```properties
SUPABASE_URL=https://<prod-project-ref>.supabase.co
SUPABASE_ANON_KEY=<prod-anon-key>
ONESIGNAL_APP_ID=<your-onesignal-app-id>
ENVIRONMENT=prod
```

---

## 5. Running the Flutter App

### Via Terminal
- **Run Dev**: `flutter run --dart-define-from-file=.env.dev`
- **Run Prod**: `flutter run --dart-define-from-file=.env.prod`
- **Build Release APK/Bundle (Prod)**: `flutter build appbundle --release --dart-define-from-file=.env.prod`
- **Build Web (Prod)**: `flutter build web --release --dart-define-from-file=.env.prod`

### Via VS Code / Android Studio
Select the desired configuration from the **Run & Debug** panel:
- `Realty Bazaar (Dev)`
- `Realty Bazaar (Prod)`
- `Realty Bazaar (Release - Prod)`
