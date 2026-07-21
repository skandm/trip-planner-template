---
name: replanner
description: Handle mid-trip disruptions to an in-progress trip without losing the plan. Trigger when the user reports a change during an in-progress trip ("I-70 is closed", "we're too tired to drive 6h tomorrow", "the hotel cancelled on us"), or explicitly asks to re-plan from a given day ("re-plan from Thursday onward"). Reads trips/<trip>/trip.md as ground truth (the user may have hand-edited it on the road), changes only the disruption-affected segments/days, shows a before/after diff before writing, and logs a dated entry explaining what changed and why. Never silently drops hard traveler constraints or hard deadlines.
---

# Replanner

This skill adjusts a trip already underway, changing as little as possible.

## Step 1: Read the file as ground truth

Read `trips/<trip>/trip.md` fresh — don't rely on what you remember from earlier in the conversation. The user may have hand-edited it on the road (a stay they booked themselves, a day they already skipped); per workspace conventions, the file wins over conversation memory whenever they conflict.

Also read `profiles/travelers.md` — hard constraints and logistics don't change just because plans did.

**Running outside the repo** (e.g. a claude.ai chat with no files attached) — ask the user to attach their `trip.md`; it's this skill's explicit ground truth, so there's nothing to diff against without it. Carry through the same process below, then in Step 5, instead of writing to disk, output the full updated file content back as a fenced markdown block for the user to save over their own copy.

## Step 2: Scope the disruption precisely

Identify exactly which days/segments the disruption touches. A road closure affects the segments using that road; fatigue affects tomorrow's drive block, not the whole trip; a cancelled hotel affects one night's Stays entry. Everything outside that scope must stay byte-for-byte identical — this is a minimal-diff operation, not a re-plan from scratch.

## Step 3: Recompute only the affected part

- **Route changes** — reuse the constraint-deriving and option-proposing approach from **route-planner** (daily driving limits, motion sickness, driver availability) rather than re-deriving it from scratch. Propose alternatives for the affected segment only. Regenerate that segment's `Map:` link from the new waypoints — a stale map pointing at the old, closed, or superseded route is worse than none.
- **Food/stay changes** — reuse **food-scout**'s filter/rank approach for any meal or stay that falls out due to the disruption (e.g. a day shifting means a previously scouted lunch spot's hours no longer fit). Carry over or regenerate that place's hyperlink the same way food-scout does, and if a route Map link included the old spot as a waypoint, swap it for the new one.
- **Never relax a hard constraint or hard deadline to make the replan easier.** If a disruption makes a hard deadline (flight, non-refundable reservation) genuinely unreachable, or makes a hard traveler constraint (allergy, medical need) impossible to honor on the new plan, stop and surface this explicitly to the user rather than quietly dropping it or picking the least-bad silent option.

## Step 4: Show before/after, then confirm

Before writing anything, show the user a compact diff of the affected days only: what the plan said before, what it would say after. Get their go-ahead. This is not optional — a replan is a real change to a trip in progress, and the user should see it before it's locked in.

## Step 5: Write back, same turn

Once confirmed, update `trip.md` in the same turn (or, if running standalone with no workspace per Step 1, output the full updated file content as a fenced markdown block for the user to save in place of their attached copy):

- **Affected Route/Stays/Food entries** — updated in place, matching existing formatting conventions in the file.
- **Open items** — add anything the replan surfaced (rebooking needed, refund to chase, reservation to move), don't just leave it implied in the Log.
- **Log** — append a dated entry: `<date> — replanned from Day N: <what changed and why>`. Every replan gets a Log entry; this is the trail that lets a future session (or the user, scanning the file) understand why the plan diverged from the original.
- **status** — set to `in-progress` if it isn't already (a replan implies the trip has started).

## Step 6: Hand off

Confirm what changed and what's still open: "Updated Day 3 to route around the I-70 closure — costs you 40 min but keeps the 6pm arrival. Still need to rebook North Platte since the new route skips it." If downstream days now need re-scouting (a stay or meal that no longer makes sense), name it as the next step rather than leaving it implicit in the diff.
