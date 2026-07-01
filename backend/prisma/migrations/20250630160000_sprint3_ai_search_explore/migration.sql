-- Sprint 3: AI, Search & Explore

CREATE TABLE IF NOT EXISTS "ai_conversations" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "title" TEXT,
    "mode" TEXT NOT NULL DEFAULT 'driving_assistant',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    CONSTRAINT "ai_conversations_pkey" PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS "ai_messages" (
    "id" UUID NOT NULL,
    "conversation_id" UUID NOT NULL,
    "role" TEXT NOT NULL,
    "content" TEXT NOT NULL,
    "tokens_used" INTEGER,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "ai_messages_pkey" PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS "search_history" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "query" TEXT NOT NULL,
    "result_count" INTEGER NOT NULL DEFAULT 0,
    "latitude" DOUBLE PRECISION,
    "longitude" DOUBLE PRECISION,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "search_history_pkey" PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS "saved_searches" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "label" TEXT NOT NULL,
    "query" TEXT NOT NULL,
    "latitude" DOUBLE PRECISION,
    "longitude" DOUBLE PRECISION,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "saved_searches_pkey" PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS "place_reviews" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "place_id" TEXT NOT NULL,
    "place_name" TEXT NOT NULL,
    "rating" INTEGER NOT NULL,
    "comment" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "place_reviews_pkey" PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS "recommendations" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "type" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "latitude" DOUBLE PRECISION,
    "longitude" DOUBLE PRECISION,
    "priority" INTEGER NOT NULL DEFAULT 0,
    "metadata" JSONB,
    "expires_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "recommendations_pkey" PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS "poi_cache" (
    "id" UUID NOT NULL,
    "cache_key" TEXT NOT NULL,
    "category" TEXT NOT NULL,
    "latitude" DOUBLE PRECISION NOT NULL,
    "longitude" DOUBLE PRECISION NOT NULL,
    "radius_km" DOUBLE PRECISION NOT NULL,
    "payload" JSONB NOT NULL,
    "expires_at" TIMESTAMP(3) NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "poi_cache_pkey" PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS "weather_cache" (
    "id" UUID NOT NULL,
    "cache_key" TEXT NOT NULL,
    "latitude" DOUBLE PRECISION NOT NULL,
    "longitude" DOUBLE PRECISION NOT NULL,
    "payload" JSONB NOT NULL,
    "expires_at" TIMESTAMP(3) NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "weather_cache_pkey" PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS "traffic_cache" (
    "id" UUID NOT NULL,
    "cache_key" TEXT NOT NULL,
    "latitude" DOUBLE PRECISION NOT NULL,
    "longitude" DOUBLE PRECISION NOT NULL,
    "payload" JSONB NOT NULL,
    "expires_at" TIMESTAMP(3) NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "traffic_cache_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX IF NOT EXISTS "poi_cache_cache_key_key" ON "poi_cache"("cache_key");
CREATE UNIQUE INDEX IF NOT EXISTS "weather_cache_cache_key_key" ON "weather_cache"("cache_key");
CREATE UNIQUE INDEX IF NOT EXISTS "traffic_cache_cache_key_key" ON "traffic_cache"("cache_key");
CREATE INDEX IF NOT EXISTS "ai_conversations_user_id_updated_at_idx" ON "ai_conversations"("user_id", "updated_at");
CREATE INDEX IF NOT EXISTS "ai_messages_conversation_id_created_at_idx" ON "ai_messages"("conversation_id", "created_at");
CREATE INDEX IF NOT EXISTS "search_history_user_id_created_at_idx" ON "search_history"("user_id", "created_at");
CREATE INDEX IF NOT EXISTS "saved_searches_user_id_idx" ON "saved_searches"("user_id");
CREATE INDEX IF NOT EXISTS "place_reviews_place_id_idx" ON "place_reviews"("place_id");
CREATE INDEX IF NOT EXISTS "place_reviews_user_id_idx" ON "place_reviews"("user_id");
CREATE INDEX IF NOT EXISTS "recommendations_user_id_type_idx" ON "recommendations"("user_id", "type");
CREATE INDEX IF NOT EXISTS "recommendations_user_id_expires_at_idx" ON "recommendations"("user_id", "expires_at");
CREATE INDEX IF NOT EXISTS "poi_cache_expires_at_idx" ON "poi_cache"("expires_at");
CREATE INDEX IF NOT EXISTS "weather_cache_expires_at_idx" ON "weather_cache"("expires_at");
CREATE INDEX IF NOT EXISTS "traffic_cache_expires_at_idx" ON "traffic_cache"("expires_at");

ALTER TABLE "ai_conversations" DROP CONSTRAINT IF EXISTS "ai_conversations_user_id_fkey";
ALTER TABLE "ai_conversations" ADD CONSTRAINT "ai_conversations_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "ai_messages" DROP CONSTRAINT IF EXISTS "ai_messages_conversation_id_fkey";
ALTER TABLE "ai_messages" ADD CONSTRAINT "ai_messages_conversation_id_fkey" FOREIGN KEY ("conversation_id") REFERENCES "ai_conversations"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "search_history" DROP CONSTRAINT IF EXISTS "search_history_user_id_fkey";
ALTER TABLE "search_history" ADD CONSTRAINT "search_history_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "saved_searches" DROP CONSTRAINT IF EXISTS "saved_searches_user_id_fkey";
ALTER TABLE "saved_searches" ADD CONSTRAINT "saved_searches_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "place_reviews" DROP CONSTRAINT IF EXISTS "place_reviews_user_id_fkey";
ALTER TABLE "place_reviews" ADD CONSTRAINT "place_reviews_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "recommendations" DROP CONSTRAINT IF EXISTS "recommendations_user_id_fkey";
ALTER TABLE "recommendations" ADD CONSTRAINT "recommendations_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
