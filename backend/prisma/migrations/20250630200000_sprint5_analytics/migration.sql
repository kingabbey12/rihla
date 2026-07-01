-- Sprint 5: Analytics Platform

CREATE TABLE IF NOT EXISTS "user_statistics" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "trips_completed" INTEGER NOT NULL DEFAULT 0,
    "trips_cancelled" INTEGER NOT NULL DEFAULT 0,
    "total_distance_km" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "total_driving_seconds" INTEGER NOT NULL DEFAULT 0,
    "total_idle_seconds" INTEGER NOT NULL DEFAULT 0,
    "average_speed_kmh" DOUBLE PRECISION,
    "max_speed_kmh" DOUBLE PRECISION,
    "harsh_braking_count" INTEGER NOT NULL DEFAULT 0,
    "rapid_acceleration_count" INTEGER NOT NULL DEFAULT 0,
    "sharp_turn_count" INTEGER NOT NULL DEFAULT 0,
    "off_route_count" INTEGER NOT NULL DEFAULT 0,
    "traffic_delay_seconds" INTEGER NOT NULL DEFAULT 0,
    "night_driving_seconds" INTEGER NOT NULL DEFAULT 0,
    "rain_driving_seconds" INTEGER NOT NULL DEFAULT 0,
    "fog_driving_seconds" INTEGER NOT NULL DEFAULT 0,
    "heat_exposure_minutes" INTEGER NOT NULL DEFAULT 0,
    "journey_completion_rate" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "fuel_litres_estimate" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "ev_kwh_estimate" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "co2_kg_estimate" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "current_driving_score" INTEGER NOT NULL DEFAULT 0,
    "last_calculated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    CONSTRAINT "user_statistics_pkey" PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS "driving_scores" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "score" INTEGER NOT NULL,
    "factors" JSONB NOT NULL,
    "period_start" TIMESTAMP(3) NOT NULL,
    "period_end" TIMESTAMP(3) NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "driving_scores_pkey" PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS "journey_analytics" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "journey_id" UUID NOT NULL,
    "session_id" UUID,
    "distance_km" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "driving_seconds" INTEGER NOT NULL DEFAULT 0,
    "idle_seconds" INTEGER NOT NULL DEFAULT 0,
    "average_speed_kmh" DOUBLE PRECISION,
    "max_speed_kmh" DOUBLE PRECISION,
    "harsh_braking" INTEGER NOT NULL DEFAULT 0,
    "rapid_acceleration" INTEGER NOT NULL DEFAULT 0,
    "sharp_turns" INTEGER NOT NULL DEFAULT 0,
    "off_route_count" INTEGER NOT NULL DEFAULT 0,
    "traffic_delay_seconds" INTEGER NOT NULL DEFAULT 0,
    "night_driving_seconds" INTEGER NOT NULL DEFAULT 0,
    "rain_driving_seconds" INTEGER NOT NULL DEFAULT 0,
    "fog_driving_seconds" INTEGER NOT NULL DEFAULT 0,
    "heat_exposure_minutes" INTEGER NOT NULL DEFAULT 0,
    "fuel_litres_estimate" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "ev_kwh_estimate" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "co2_kg_estimate" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "completed" BOOLEAN NOT NULL DEFAULT false,
    "destination_name" TEXT,
    "metrics" JSONB,
    "computed_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "journey_analytics_pkey" PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS "vehicle_analytics" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "vehicle_id" UUID,
    "total_distance_km" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "total_trips" INTEGER NOT NULL DEFAULT 0,
    "fuel_litres" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "ev_kwh" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "co2_kg" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "average_score" INTEGER NOT NULL DEFAULT 0,
    "period_start" TIMESTAMP(3) NOT NULL,
    "period_end" TIMESTAMP(3) NOT NULL,
    "metrics" JSONB,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "vehicle_analytics_pkey" PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS "weekly_reports" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "week_start" TIMESTAMP(3) NOT NULL,
    "week_end" TIMESTAMP(3) NOT NULL,
    "payload" JSONB NOT NULL,
    "generated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "weekly_reports_pkey" PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS "monthly_reports" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "month" INTEGER NOT NULL,
    "year" INTEGER NOT NULL,
    "payload" JSONB NOT NULL,
    "generated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "monthly_reports_pkey" PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS "achievements" (
    "id" UUID NOT NULL,
    "code" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "category" TEXT NOT NULL,
    "criteria" JSONB NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "achievements_pkey" PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS "user_achievements" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "achievement_id" UUID NOT NULL,
    "earned_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "user_achievements_pkey" PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS "leaderboards" (
    "id" UUID NOT NULL,
    "scope" TEXT NOT NULL,
    "metric" TEXT NOT NULL,
    "period" TEXT NOT NULL,
    "rankings" JSONB NOT NULL,
    "generated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "leaderboards_pkey" PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS "analytics_events" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "event_type" TEXT NOT NULL,
    "source_id" TEXT,
    "payload" JSONB,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "analytics_events_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX IF NOT EXISTS "user_statistics_user_id_key" ON "user_statistics"("user_id");
CREATE UNIQUE INDEX IF NOT EXISTS "journey_analytics_journey_id_key" ON "journey_analytics"("journey_id");
CREATE UNIQUE INDEX IF NOT EXISTS "weekly_reports_user_id_week_start_key" ON "weekly_reports"("user_id", "week_start");
CREATE UNIQUE INDEX IF NOT EXISTS "monthly_reports_user_id_month_year_key" ON "monthly_reports"("user_id", "month", "year");
CREATE UNIQUE INDEX IF NOT EXISTS "achievements_code_key" ON "achievements"("code");
CREATE UNIQUE INDEX IF NOT EXISTS "user_achievements_user_id_achievement_id_key" ON "user_achievements"("user_id", "achievement_id");
CREATE UNIQUE INDEX IF NOT EXISTS "leaderboards_scope_metric_period_key" ON "leaderboards"("scope", "metric", "period");
CREATE INDEX IF NOT EXISTS "driving_scores_user_id_created_at_idx" ON "driving_scores"("user_id", "created_at");
CREATE INDEX IF NOT EXISTS "journey_analytics_user_id_computed_at_idx" ON "journey_analytics"("user_id", "computed_at");
CREATE INDEX IF NOT EXISTS "vehicle_analytics_user_id_period_end_idx" ON "vehicle_analytics"("user_id", "period_end");
CREATE INDEX IF NOT EXISTS "user_achievements_user_id_earned_at_idx" ON "user_achievements"("user_id", "earned_at");
CREATE INDEX IF NOT EXISTS "analytics_events_user_id_event_type_idx" ON "analytics_events"("user_id", "event_type");
CREATE INDEX IF NOT EXISTS "analytics_events_user_id_created_at_idx" ON "analytics_events"("user_id", "created_at");

ALTER TABLE "user_statistics" DROP CONSTRAINT IF EXISTS "user_statistics_user_id_fkey";
ALTER TABLE "user_statistics" ADD CONSTRAINT "user_statistics_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "driving_scores" DROP CONSTRAINT IF EXISTS "driving_scores_user_id_fkey";
ALTER TABLE "driving_scores" ADD CONSTRAINT "driving_scores_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "journey_analytics" DROP CONSTRAINT IF EXISTS "journey_analytics_user_id_fkey";
ALTER TABLE "journey_analytics" ADD CONSTRAINT "journey_analytics_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "vehicle_analytics" DROP CONSTRAINT IF EXISTS "vehicle_analytics_user_id_fkey";
ALTER TABLE "vehicle_analytics" ADD CONSTRAINT "vehicle_analytics_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "weekly_reports" DROP CONSTRAINT IF EXISTS "weekly_reports_user_id_fkey";
ALTER TABLE "weekly_reports" ADD CONSTRAINT "weekly_reports_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "monthly_reports" DROP CONSTRAINT IF EXISTS "monthly_reports_user_id_fkey";
ALTER TABLE "monthly_reports" ADD CONSTRAINT "monthly_reports_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "user_achievements" DROP CONSTRAINT IF EXISTS "user_achievements_user_id_fkey";
ALTER TABLE "user_achievements" ADD CONSTRAINT "user_achievements_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "user_achievements" DROP CONSTRAINT IF EXISTS "user_achievements_achievement_id_fkey";
ALTER TABLE "user_achievements" ADD CONSTRAINT "user_achievements_achievement_id_fkey" FOREIGN KEY ("achievement_id") REFERENCES "achievements"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "analytics_events" DROP CONSTRAINT IF EXISTS "analytics_events_user_id_fkey";
ALTER TABLE "analytics_events" ADD CONSTRAINT "analytics_events_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
