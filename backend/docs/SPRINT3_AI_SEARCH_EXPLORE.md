# Sprint 3 — AI, Search & Explore

Production backend for UAE-biased search, live POI explore, unified AI context, and recommendations.

## Services

| Service | Module |
|---------|--------|
| AI Service | `src/modules/ai/` |
| Journey Advisor | `src/modules/ai/journey-advisor.service.ts` |
| Search / Nominatim | `src/modules/search/` |
| Places | `src/modules/search/places.service.ts` |
| Explore Engine | `src/modules/explore/explore-engine.service.ts` |
| POI Aggregator | `src/modules/explore/poi-aggregator.service.ts` |
| Weather Context | `src/modules/context/weather-context.service.ts` |
| Traffic Context | `src/modules/context/traffic-context.service.ts` |
| Context Engine | `src/modules/context/context-engine.service.ts` |
| Recommendation Engine | `src/modules/recommendations/` |
| Cache (Redis + DB) | `src/shared/cache/` |

## External APIs

- **Nominatim** — UAE viewbox `51.5,22.5,56.5,26.5`, `countrycodes=ae`
- **Overpass** — OSM POIs (hospitals, restaurants, mosques, etc.)
- **OpenChargeMap** — EV chargers
- **Open-Meteo** — weather
- **TomTom** — traffic flow + POI (when `TOMTOM_API_KEY` set)
- **OpenAI** — chat completions (deterministic fallback if key missing)

## API Endpoints

### AI (`/api/v1/ai`)
- `POST /chat` — rate-limited 20/min
- `POST /journey-advice`
- `POST /recommendations`
- `POST /explain-route`
- `GET /history`
- `DELETE /history/:id`

### Search (`/api/v1/search`)
- `GET /` — query, category, emirate
- `GET /reverse`
- `GET /history`
- `GET /saved`
- `POST /saved`
- `POST /reviews`

### Explore (`/api/v1/explore`)
- `GET /categories`
- `GET /nearby`
- `GET /nearby-all`

## Database (migration `20250630160000_sprint3_ai_search_explore`)

`ai_conversations`, `ai_messages`, `search_history`, `saved_searches`, `place_reviews`, `recommendations`, `poi_cache`, `weather_cache`, `traffic_cache`

## Verification

```bash
cd backend
npm install
npm test
npx prisma migrate deploy
docker compose -f docker/docker-compose.yml up --build
```

Set `OPENAI_API_KEY`, `TOMTOM_API_KEY`, and `OPENCHARGEMAP_API_KEY` in `.env` for full live integrations.
