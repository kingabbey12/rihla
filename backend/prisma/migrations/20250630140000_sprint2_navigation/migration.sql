-- AlterTable journeys
ALTER TABLE "journeys" ADD COLUMN IF NOT EXISTS "mode" TEXT NOT NULL DEFAULT 'driving';

-- AlterTable routes
ALTER TABLE "routes" ADD COLUMN IF NOT EXISTS "mode" TEXT NOT NULL DEFAULT 'driving';
ALTER TABLE "routes" ADD COLUMN IF NOT EXISTS "encoded_polyline6" TEXT;
ALTER TABLE "routes" ADD COLUMN IF NOT EXISTS "instructions" JSONB;
ALTER TABLE "routes" ADD COLUMN IF NOT EXISTS "elevation_gain_m" DOUBLE PRECISION;
ALTER TABLE "routes" ADD COLUMN IF NOT EXISTS "traffic_weight" DOUBLE PRECISION;
ALTER TABLE "routes" ADD COLUMN IF NOT EXISTS "is_alternative" BOOLEAN NOT NULL DEFAULT false;

-- AlterTable navigation_sessions
ALTER TABLE "navigation_sessions" ADD COLUMN IF NOT EXISTS "journey_id" UUID;
ALTER TABLE "navigation_sessions" ADD COLUMN IF NOT EXISTS "mode" TEXT NOT NULL DEFAULT 'driving';
ALTER TABLE "navigation_sessions" ADD COLUMN IF NOT EXISTS "heading_deg" DOUBLE PRECISION;
ALTER TABLE "navigation_sessions" ADD COLUMN IF NOT EXISTS "distance_travelled_km" DOUBLE PRECISION NOT NULL DEFAULT 0;
ALTER TABLE "navigation_sessions" ADD COLUMN IF NOT EXISTS "average_speed_kmh" DOUBLE PRECISION;
ALTER TABLE "navigation_sessions" ADD COLUMN IF NOT EXISTS "is_off_route" BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE "navigation_sessions" ADD COLUMN IF NOT EXISTS "paused_at" TIMESTAMP(3);
ALTER TABLE "navigation_sessions" ADD COLUMN IF NOT EXISTS "arrived_at" TIMESTAMP(3);

-- CreateTable route_segments
CREATE TABLE IF NOT EXISTS "route_segments" (
    "id" UUID NOT NULL,
    "route_id" UUID NOT NULL,
    "segment_index" INTEGER NOT NULL,
    "start_lat" DOUBLE PRECISION NOT NULL,
    "start_lng" DOUBLE PRECISION NOT NULL,
    "end_lat" DOUBLE PRECISION NOT NULL,
    "end_lng" DOUBLE PRECISION NOT NULL,
    "distance_km" DOUBLE PRECISION NOT NULL,
    "duration_seconds" INTEGER NOT NULL,
    "instruction" TEXT NOT NULL,
    "maneuver_type" TEXT NOT NULL,
    "polyline" TEXT NOT NULL,
    CONSTRAINT "route_segments_pkey" PRIMARY KEY ("id")
);

-- CreateTable journey_points
CREATE TABLE IF NOT EXISTS "journey_points" (
    "id" UUID NOT NULL,
    "session_id" UUID NOT NULL,
    "sequence" INTEGER NOT NULL,
    "latitude" DOUBLE PRECISION NOT NULL,
    "longitude" DOUBLE PRECISION NOT NULL,
    "speed_kmh" DOUBLE PRECISION,
    "heading_deg" DOUBLE PRECISION,
    "accuracy_m" DOUBLE PRECISION,
    "altitude_m" DOUBLE PRECISION,
    "recorded_at" TIMESTAMP(3) NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "journey_points_pkey" PRIMARY KEY ("id")
);

-- CreateTable route_events
CREATE TABLE IF NOT EXISTS "route_events" (
    "id" UUID NOT NULL,
    "session_id" UUID NOT NULL,
    "event_type" TEXT NOT NULL,
    "payload" JSONB,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "route_events_pkey" PRIMARY KEY ("id")
);

-- CreateTable journey_statistics
CREATE TABLE IF NOT EXISTS "journey_statistics" (
    "id" UUID NOT NULL,
    "session_id" UUID NOT NULL,
    "distance_travelled_km" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "average_speed_kmh" DOUBLE PRECISION,
    "max_speed_kmh" DOUBLE PRECISION,
    "duration_seconds" INTEGER NOT NULL DEFAULT 0,
    "off_route_count" INTEGER NOT NULL DEFAULT 0,
    "points_recorded" INTEGER NOT NULL DEFAULT 0,
    "arrival_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    CONSTRAINT "journey_statistics_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX IF NOT EXISTS "route_segments_route_id_segment_index_idx" ON "route_segments"("route_id", "segment_index");
CREATE INDEX IF NOT EXISTS "journey_points_session_id_sequence_idx" ON "journey_points"("session_id", "sequence");
CREATE INDEX IF NOT EXISTS "journey_points_session_id_recorded_at_idx" ON "journey_points"("session_id", "recorded_at");
CREATE INDEX IF NOT EXISTS "route_events_session_id_event_type_idx" ON "route_events"("session_id", "event_type");
CREATE INDEX IF NOT EXISTS "route_events_session_id_created_at_idx" ON "route_events"("session_id", "created_at");
CREATE UNIQUE INDEX IF NOT EXISTS "journey_statistics_session_id_key" ON "journey_statistics"("session_id");

-- AddForeignKey
ALTER TABLE "route_segments" DROP CONSTRAINT IF EXISTS "route_segments_route_id_fkey";
ALTER TABLE "route_segments" ADD CONSTRAINT "route_segments_route_id_fkey" FOREIGN KEY ("route_id") REFERENCES "routes"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "journey_points" DROP CONSTRAINT IF EXISTS "journey_points_session_id_fkey";
ALTER TABLE "journey_points" ADD CONSTRAINT "journey_points_session_id_fkey" FOREIGN KEY ("session_id") REFERENCES "navigation_sessions"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "route_events" DROP CONSTRAINT IF EXISTS "route_events_session_id_fkey";
ALTER TABLE "route_events" ADD CONSTRAINT "route_events_session_id_fkey" FOREIGN KEY ("session_id") REFERENCES "navigation_sessions"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "journey_statistics" DROP CONSTRAINT IF EXISTS "journey_statistics_session_id_fkey";
ALTER TABLE "journey_statistics" ADD CONSTRAINT "journey_statistics_session_id_fkey" FOREIGN KEY ("session_id") REFERENCES "navigation_sessions"("id") ON DELETE CASCADE ON UPDATE CASCADE;
