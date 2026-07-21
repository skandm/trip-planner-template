---
name: itinerary-builder
description: Assemble a trip's day-by-day schedule once route, stays, and food are mostly decided. Trigger when the user says "build the itinerary" (or equivalent), when trips/<trip>/trip.md's Route/Stays/Food sections are largely settled, or during the itinerary phase of "plan my whole trip" (travelers -> route -> stays/food -> itinerary). Assembles departure times, drive blocks with breaks, meal stops, check-ins, and anchor activities, respecting traveler logistics like early bird/night owl rhythms and motion-sickness breaks. Flags unresolved blockers instead of guessing, and flips trip status planning -> ready when complete.
---

# Itinerary builder

This skill turns a mostly-decided `trip.md` into a concrete hour-by-hour schedule.

## Step 1: Check readiness before scheduling

Read `trips/<trip>/trip.md` and `profiles/travelers.md`. Assemble the schedule only from what's already decided — this skill never invents a booking, a restaurant, or a time slot to fill a gap.

**Running outside the repo** (e.g. a claude.ai chat with no files attached) — ask the user to attach their `trip.md`. There's nothing to schedule without it; say so plainly rather than improvising an itinerary from memory or invented details.

Scan for blockers:
- Stays marked `unbooked` or missing.
- Food slots marked `_to scout_` or without a chosen option.
- Route segments marked `tentative`.

If blockers exist, **surface them rather than schedule around them**. Tell the user what's missing and either wait, or build the itinerary around the settled parts and leave the blocked days as open placeholders with a note. Don't silently pick a restaurant or hotel just to complete the schedule — that's food-scout's and the user's call, not this skill's.

If a Budget section exists, do a quick sanity check: does its lodging/fuel actuals line up with what Route and Stays actually settled on? A mismatch (e.g. a stay chosen at $210/night against a stated $160 cap) isn't a blocker on its own, but flag it rather than silently scheduling around a plan that's quietly over budget.

## Step 2: Apply traveler logistics and interests

Pull from `profiles/travelers.md` Logistics:
- **Early bird vs. night owl** — set departure and dinner times accordingly; don't schedule a 6am departure for a stated night owl without flagging the tension.
- **Motion sickness** — insert stop breaks on driving legs (roughly every 1.5-2h), matching what route-planner already flagged.
- **Kids or mobility limits** — build in slack; avoid back-to-back long activities with no downtime.
- **Driving shifts** — if multiple people share driving, note who's driving which leg if that was decided.

Pull from `profiles/travelers.md` Interests when picking each day's anchor activity: favor stops the group's stated interests actually match (a museum afternoon for someone who loves museums, a trailhead for the hiker), and skip options that clash with a stated dislike. If a city offers several viable anchors and no interest data points to one, ask rather than guessing — don't silently default to the generic tourist option.

## Step 3: Assemble the schedule

Write into `trip.md` as a new **Itinerary** section (or per-day subsections under existing days — match whatever structure the trip already uses). Per day, include:

- Departure time and place.
- Drive blocks with break points.
- Meal stops with arrival times (pulled from the Food section's chosen options).
- Check-in time at the night's stay.
- Any anchor activity for the day.

```markdown
## Itinerary

### Day 1 — <date>
- 8:00 depart <origin>
- 10:30 stop (15 min) — <reason, e.g. "stretch break">
- 12:30 lunch — [<chosen food option>](<maps place link>)
- 15:00 arrive <city>
- 15:30 check in — <stay>
- Evening: [<anchor activity, if any>](<maps place link>)
```

- **Reuse links, don't reinvent them.** Meal stops already carry a Google Maps place link from food-scout's Food section — copy it over rather than re-deriving. Any *new* anchor activity this skill introduces (a museum, a trailhead, a viewpoint) gets its own place link the same way food-scout and route-planner build theirs: `https://www.google.com/maps/search/?api=1&query=<url-encoded "Name, City, State">`, plus the real website if you found one.
- **Mark new anchors on the day's route map, if one exists.** If that day already has a Route section with a `Map:` link, add the anchor activity to its waypoints too (same mechanic food-scout uses for meal stops) so it shows up as a pin alongside the drive — update the Route section's `Map:` line in the same turn. Skip this if the day has no driving segment or no Map link yet.

Keep it human-readable and hand-editable — this is a markdown file the user edits directly, not a generated artifact to be regenerated wholesale each time.

## Step 4: Flip status when actually complete

Set `status: ready` in the frontmatter only when every day has a full schedule with no blockers left. If any day is still incomplete, leave `status: planning` and list the specific gaps under **Open items** — don't flip status to make the trip look more finished than it is.

## Step 5: Optional export

If the user wants something to carry on the road, offer a companion export in the trip folder next to `trip.md` — e.g. `itinerary.md` (a clean printable copy) or an `.ics` file for calendar import. These are exports, not the source of truth; `trip.md` stays authoritative and the export should be regenerated from it, not hand-maintained separately.

## Step 6: Log and hand off

Append a dated `Log` entry noting the itinerary was built (or partially built, naming what's still open). If status flipped to `ready`, say so plainly — that's the signal the trip is set. If blockers remain, name them as the next concrete step ("Once North Platte dinner is scouted, Day 2 is ready too").
