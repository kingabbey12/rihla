-- Sprint 4: Emergency Platform

CREATE TABLE IF NOT EXISTS "emergency_contacts" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "name_enc" TEXT NOT NULL,
    "phone_enc" TEXT NOT NULL,
    "relationship" TEXT,
    "is_primary" BOOLEAN NOT NULL DEFAULT false,
    "notify_on_sos" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    CONSTRAINT "emergency_contacts_pkey" PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS "medical_profiles" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "blood_type_enc" TEXT,
    "allergies_enc" TEXT,
    "medications_enc" TEXT,
    "conditions_enc" TEXT,
    "notes_enc" TEXT,
    "organ_donor" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    CONSTRAINT "medical_profiles_pkey" PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS "vehicle_profiles" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "vehicle_id" UUID,
    "make_enc" TEXT,
    "model_enc" TEXT,
    "color_enc" TEXT,
    "license_plate_enc" TEXT,
    "insurance_provider_enc" TEXT,
    "insurance_policy_enc" TEXT,
    "roadside_membership_enc" TEXT,
    "vin_enc" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    CONSTRAINT "vehicle_profiles_pkey" PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS "sos_requests" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'active',
    "latitude" DOUBLE PRECISION NOT NULL,
    "longitude" DOUBLE PRECISION NOT NULL,
    "heading_deg" DOUBLE PRECISION,
    "speed_kmh" DOUBLE PRECISION,
    "battery_level" DOUBLE PRECISION,
    "device_id" TEXT,
    "device_platform" TEXT,
    "vehicle_snapshot" JSONB,
    "medical_snapshot" JSONB,
    "contacts_snapshot" JSONB,
    "started_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "cancelled_at" TIMESTAMP(3),
    "resolved_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    CONSTRAINT "sos_requests_pkey" PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS "roadside_requests" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "type" TEXT NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'pending',
    "latitude" DOUBLE PRECISION NOT NULL,
    "longitude" DOUBLE PRECISION NOT NULL,
    "description" TEXT,
    "provider" TEXT,
    "eta_minutes" INTEGER,
    "resolved_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    CONSTRAINT "roadside_requests_pkey" PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS "incident_reports" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "type" TEXT NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'submitted',
    "latitude" DOUBLE PRECISION NOT NULL,
    "longitude" DOUBLE PRECISION NOT NULL,
    "description" TEXT,
    "image_urls" JSONB,
    "voice_note_url" TEXT,
    "voice_note_meta" JSONB,
    "reporter_name" TEXT,
    "reporter_phone" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    CONSTRAINT "incident_reports_pkey" PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS "live_location_sessions" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "share_token_hash" TEXT NOT NULL,
    "channel_name" TEXT NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'active',
    "expires_at" TIMESTAMP(3) NOT NULL,
    "current_lat" DOUBLE PRECISION,
    "current_lng" DOUBLE PRECISION,
    "heading_deg" DOUBLE PRECISION,
    "speed_kmh" DOUBLE PRECISION,
    "started_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "paused_at" TIMESTAMP(3),
    "ended_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    CONSTRAINT "live_location_sessions_pkey" PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS "emergency_dispatch_events" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "source_type" TEXT NOT NULL,
    "source_id" UUID NOT NULL,
    "event_type" TEXT NOT NULL,
    "payload" JSONB,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "emergency_dispatch_events_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX IF NOT EXISTS "medical_profiles_user_id_key" ON "medical_profiles"("user_id");
CREATE UNIQUE INDEX IF NOT EXISTS "vehicle_profiles_user_id_key" ON "vehicle_profiles"("user_id");
CREATE UNIQUE INDEX IF NOT EXISTS "live_location_sessions_share_token_hash_key" ON "live_location_sessions"("share_token_hash");
CREATE INDEX IF NOT EXISTS "emergency_contacts_user_id_idx" ON "emergency_contacts"("user_id");
CREATE INDEX IF NOT EXISTS "sos_requests_user_id_status_idx" ON "sos_requests"("user_id", "status");
CREATE INDEX IF NOT EXISTS "roadside_requests_user_id_status_idx" ON "roadside_requests"("user_id", "status");
CREATE INDEX IF NOT EXISTS "incident_reports_user_id_created_at_idx" ON "incident_reports"("user_id", "created_at");
CREATE INDEX IF NOT EXISTS "live_location_sessions_user_id_status_idx" ON "live_location_sessions"("user_id", "status");
CREATE INDEX IF NOT EXISTS "live_location_sessions_expires_at_idx" ON "live_location_sessions"("expires_at");
CREATE INDEX IF NOT EXISTS "emergency_dispatch_events_source_type_source_id_idx" ON "emergency_dispatch_events"("source_type", "source_id");
CREATE INDEX IF NOT EXISTS "emergency_dispatch_events_user_id_created_at_idx" ON "emergency_dispatch_events"("user_id", "created_at");

ALTER TABLE "emergency_contacts" DROP CONSTRAINT IF EXISTS "emergency_contacts_user_id_fkey";
ALTER TABLE "emergency_contacts" ADD CONSTRAINT "emergency_contacts_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "medical_profiles" DROP CONSTRAINT IF EXISTS "medical_profiles_user_id_fkey";
ALTER TABLE "medical_profiles" ADD CONSTRAINT "medical_profiles_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "vehicle_profiles" DROP CONSTRAINT IF EXISTS "vehicle_profiles_user_id_fkey";
ALTER TABLE "vehicle_profiles" ADD CONSTRAINT "vehicle_profiles_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "sos_requests" DROP CONSTRAINT IF EXISTS "sos_requests_user_id_fkey";
ALTER TABLE "sos_requests" ADD CONSTRAINT "sos_requests_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "roadside_requests" DROP CONSTRAINT IF EXISTS "roadside_requests_user_id_fkey";
ALTER TABLE "roadside_requests" ADD CONSTRAINT "roadside_requests_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "incident_reports" DROP CONSTRAINT IF EXISTS "incident_reports_user_id_fkey";
ALTER TABLE "incident_reports" ADD CONSTRAINT "incident_reports_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "live_location_sessions" DROP CONSTRAINT IF EXISTS "live_location_sessions_user_id_fkey";
ALTER TABLE "live_location_sessions" ADD CONSTRAINT "live_location_sessions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "emergency_dispatch_events" DROP CONSTRAINT IF EXISTS "emergency_dispatch_events_user_id_fkey";
ALTER TABLE "emergency_dispatch_events" ADD CONSTRAINT "emergency_dispatch_events_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
