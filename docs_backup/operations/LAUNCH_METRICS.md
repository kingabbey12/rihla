# Launch Metrics — Rihla v1.0.0

What we track from day one and the v1.0 success targets.

## Acquisition (store consoles)
| Metric | Source | Target (first 30 days) |
| --- | --- | --- |
| Downloads | Play Console / App Store Connect | track baseline |
| Installs (retained) | Store consoles | ≥ 70% of downloads |
| Store rating | Store consoles | ≥ 4.3 |

## Activation & engagement (PostHog)
| Metric | Event / source | Target |
| --- | --- | --- |
| Activation (first journey started) | `journeyStarted` within 24h of `appOpened` | ≥ 60% of new users |
| DAU / WAU | session events | establish baseline; DAU/WAU ≥ 0.2 |
| D1 / D7 / D30 retention | cohort | D1 ≥ 35%, D7 ≥ 20%, D30 ≥ 10% |

## Core product (PostHog)
| Metric | Event | Target |
| --- | --- | --- |
| Journey completion rate | `journeyCompleted` / `journeyStarted` | ≥ 85% |
| Navigation cancellation rate | `navigationCancelled` / `journeyStarted` | ≤ 15% |
| AI usage | `aiUsage` | track adoption |
| Emergency usage | `emergencyActivated` | track (reliability ≥ 99%) |
| Offline usage | `offlineDownload` | track adoption |
| Explore usage | `exploreUsage` | track adoption |

## Reliability (crash backend + providers)
| Metric | Target |
| --- | --- |
| Crash-free sessions | ≥ 99.5% |
| Crash-free users | ≥ 99.0% |
| Cloud sync success | ≥ 98% |
| Emergency SOS reliability | ≥ 99% |

## Review cadence
Daily during launch week (health + acquisition), then weekly. Metrics below
critical thresholds trigger `operations/INCIDENT_RESPONSE.md`.
