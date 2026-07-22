# Trip planning workspace

This repo is a trip-planning workspace. The user talks about trips; you plan them using the skills in `.claude/skills/` and the state files described below. These conventions apply to every session in this folder.

## State files — check before asking

Before asking the user any question, check whether the answer already lives in a file:

- **`profiles/travelers.md`** — who travels: hard constraints (allergies, medical, religious dietary law), soft preferences, logistics. Shared across all trips. The blank starting template for this file lives in `.claude/skills/traveler-profiles/travelers.template.md` — copy it to `profiles/travelers.md` on first use; never fill it in in place.
- **`trips/<trip-name>/trip.md`** — one folder per trip, one `trip.md` as its source of truth: route, schedule, stays, food stops, budget. Supporting research or exports live next to it in the same folder.

Resolution order at the start of any trip-related request:

1. Read `profiles/travelers.md`. If missing, create it by copying `.claude/skills/traveler-profiles/travelers.template.md`. If its frontmatter says `status: template`, profiles don't exist yet → offer the traveler-profiles interview (see that skill) before deep planning. If `status: filled`, load it and briefly confirm rather than re-asking ("planning around Maya's gluten-free — still right?").
2. List `trips/`. If the request matches an existing trip folder, read its `trip.md` and resume from its current state. If it's a new trip, create `trips/<destination-mmm-yyyy>/trip.md` (e.g. `trips/nashville-aug-2026/`). If ambiguous, ask which trip.
3. Only then start planning, and only ask the user for information the files don't contain.

## Writing state back

- Any decision made in conversation (a chosen route, a booked hotel, a dietary update) gets written to the relevant file **in the same turn** it's decided. Never end a session with decisions that exist only in the chat.
- `profiles/travelers.md` changes: confirm with the user before writing (it's shared across trips), and flip `status: template` → `status: filled` on first fill.
- Keep `trip.md` human-readable — the user edits these files by hand between sessions and their edits are authoritative. If a file contradicts what you remember from conversation, the file wins.

## Boundaries

- Never write into `.claude/` — skills and their assets are logic, not state.
- Never delete or overwrite `trips/example-trip/` contents on the user's behalf unless asked — but ignore it when listing the user's real trips.
- Personal data stays in this repo's files. Don't copy traveler health information into commit messages, external services, or web searches (search "gluten-free restaurants Memphis", not "restaurants for Maya who has celiac").

## Skills in this workspace

- **traveler-profiles** — interviews the user and fills `travelers.md`. Trigger when profiles are missing, stale, or the user mentions changes to who's traveling or their needs.
- **route-planner** — turns an origin/destination/dates into a day-by-day driving route, respecting driving limits and logistics from `travelers.md`. Trigger on a new trip request or an empty/tentative Route section.
- **stay-scout** — recommends 2–3 lodging options per night, filtered by mobility/party-size/budget constraints and ranked by soft preferences (walkability, parking, price vs. the Budget cap). Trigger on lodging questions or a Stays entry marked `unbooked`.
- **food-scout** — recommends 2–3 meal options filtered by hard constraints and ranked by soft preferences. Trigger on food questions or a `_to scout_` food item.
- **itinerary-builder** — assembles the day-by-day schedule once route/stays/food are mostly decided. Trigger on "build the itinerary" or when a trip is mostly settled.
- **replanner** — adjusts an in-progress trip after a disruption with a minimal diff. Trigger when the user reports a change mid-trip or asks to re-plan from a given day.
- **trip-exporter** — renders a trip's settled plan into a shareable single-file HTML page (`trips/<trip>/itinerary.html`), scrubbed of traveler health/dietary/mobility rationale; can optionally publish it as a private Artifact link with the user's per-trip consent. Trigger on "export/share/print the trip" or as an offer once a trip goes `ready`.

Each documents its own full trigger in its SKILL.md.

When a request spans phases ("plan my whole trip"), work through them in order — travelers → route → stays/food → itinerary — reading and updating `trip.md` between phases.
