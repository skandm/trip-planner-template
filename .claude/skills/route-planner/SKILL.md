---
name: route-planner
description: Turn an origin, destination, and dates into a day-by-day driving route. Trigger when the user asks to plan a road trip ("plan a road trip from Chicago to Denver"), when a new trip folder is being created, or when an existing trips/<trip>/trip.md has an empty or tentative Route section. Reads profiles/travelers.md for driving limits, motion sickness, and who can share driving, and trip.md Parameters for dates and style. Proposes a fastest option plus 1-2 scenic options built around stops matched to the travelers' interests, each stated with total drive time, tolls, notable-stop facts, and food picks along the way, then writes the chosen route (per-day segments, decision date) and rejected options (with reason) back into trip.md.
---

# Route planner

This skill turns a trip request into a concrete route split across driving days, respecting who's actually in the car.

## Step 1: Read before asking

1. Read `profiles/travelers.md`. If missing or `status: template`, invoke the **traveler-profiles** skill first — route pacing depends on daily driving limits, motion sickness, and who can drive. Also note the party's stated Interests here (history, nature, food, quirky roadside stuff, etc.) — this is what should steer *which* stops a scenic option is built around, not a generic "pretty road."
2. Read (or create) `trips/<trip-name>/trip.md`. If the Parameters section already has origin, destination, dates, vehicle, and style, don't re-ask — confirm briefly instead ("scenic over fast, arrive by the 17th evening — still right?").
3. Only ask the user for what's genuinely missing: origin, destination, date range, any hard arrival deadline, style preference (scenic vs. fast, interstates okay or not, stops per day), and — if travelers.md has no Interests to go on — what kind of stops would make a detour worth it (nature, history, food, oddities).
4. **Running outside the repo** (e.g. a claude.ai chat with nothing attached, no `trip.md` path available) — there's no trip folder to read or create. Gather the same parameters conversationally (origin, destination, dates, style, deadline, interests), ask the user to attach their `travelers.md` if they have one, or run the traveler-profiles interview inline if they want profile-aware pacing and don't have one handy. Proceed to Step 2 with whatever's gathered, and see the standalone note under Step 4 for how to hand the result back.

## Step 2: Derive the constraints

Before proposing routes, pull the numbers that actually bound the route:

- **Daily driving limit** — from each traveler's Logistics. Use the *lowest* limit among travelers actually driving; if none is stated, default to a conservative ~6h/day and say so.
- **Motion sickness** — a traveler who gets carsick means avoid winding backroads or, if a scenic route is otherwise the right call, flag it explicitly and schedule stops every 1.5–2h.
- **Drivers available** — only travelers marked able to drive count toward shift-splitting. A route needing 8h/day with one driver is a red flag; say so rather than proposing it silently.
- **Hard deadline** — an arrival date/time marked "hard" in Parameters is a constraint, not a preference; every option must satisfy it.
- **Toll tolerance** — if travelers.md or trip.md Parameters says to avoid or minimize tolls, treat it as a soft constraint on route choice. Regardless of preference, every option still gets its toll cost stated (Step 3) — the user can't weigh "faster but tolled" without the number.

## Step 3: Propose a fastest option and 1-2 scenic options

Never propose a flat list of interchangeable options. Structure the comparison as:

- **Fastest option** — the shortest total drive time, normally via interstates/highways. This is the baseline everything else is measured against.
- **1-2 scenic options** — an alternate road built around one or more stops chosen for a reason, not just "prettier pavement." Pick stops that match the party's stated Interests (from `travelers.md`) or whatever the user said makes a detour worth it (Step 1.3). A scenic option with no real stop is just a slower fastest option — don't propose one unless it's actually earning its extra time with something to see or do.
  - Don't silently settle on a single waypoint when more than one plausible stop fits the party's Interests. For each waypoint slot, shortlist 2-3 candidates ranked best-fit-first against the stated Interests, and let the user pick rather than picking for them. Only auto-pick the top-ranked candidate if the user explicitly says to just go with your best call.

**Every option, fastest and scenic alike, states:**
- The road/route taken and day-by-day split.
- Total distance and total drive time (moving time; note separately if stops add meaningfully to the clock).
- **Tolls** — dollar estimate and which roads charge them, or "no tolls." Don't skip this because it's zero; "no tolls" is itself a comparison point.
- The tradeoff versus the other options (e.g. "1.5h faster but no stops worth the detour" vs. "adds 50 min, but that's the only way to catch the caverns").
- **A real map link** — a Google Maps directions URL the user can actually open, built from the option's real waypoints (see "Map links" below). Not a description of the route — an actual clickable link to it.

**Scenic options additionally get:**
- **Notable stops**, named explicitly (not just "a scenic overlook"), each with its own hyperlink (see "Place links" below). Where a waypoint slot has a shortlist (per Step 3 above), present all 2-3 candidates this way, ranked, not just the top pick — the user is choosing between them, not being told the answer.
- **1-2 interesting facts** per stop or per the route itself — something that makes the detour feel earned (a historical event, a geological quirk, a roadside oddity, why the road exists at all). Pull these from an actual search rather than inventing them; if you can't confirm a claim, say "worth verifying" rather than stating it as fact. For shortlisted candidates, one fact each is enough to compare; save the deeper pass for whichever one the user actually picks.

**Every option also gets a food pick or two** along the way (a lunch stop matching the day's drive, a dinner option near that night's stop), each with its own hyperlink (see "Place links" below). Apply food-scout's two-pass method — hard-constraint filter first (never surface an option that violates an allergy, medical need, or religious dietary law), then rank by soft preference — but keep it light here: one name + one line on why it fits, per stop. This is a comparison aid, not the full food-scout writeup; food-scout does the deeper 2-3-option pass later when that day's food slot is actually being scouted.

**Place links** — every named place this skill surfaces (notable stop or food pick, not just the route itself) gets a real hyperlink, same convention food-scout uses: a Google Maps place-search link built from the name and city, no API key needed — `https://www.google.com/maps/search/?api=1&query=<url-encoded "Name, City, State">`. Add the place's real website too if you found one during research; never fabricate one.

**Map links** — every option also gets a single real, clickable Google Maps *directions* link for the whole route, not just a text description. Build it from Google's URL API (no key required):

```
https://www.google.com/maps/dir/?api=1&origin=<origin>&destination=<destination>&waypoints=<stop1>|<stop2>|...&travelmode=driving
```

- `origin` / `destination` — the trip's actual start and end (address or "City, State" is fine).
- `waypoints` — every notable stop **and** food pick on that option, in the order they're actually passed, pipe-separated (`|`), so they show up as pins on the route itself rather than only existing as separate links. Fastest options with no stops can omit `waypoints` entirely. If a food pick is enough of a detour that routing through it would meaningfully distort the drive-time estimate, leave it out of `waypoints` and rely on its standalone place link instead — say so rather than silently folding in a detour.
- URL-encode each place (spaces → `+` or `%20`, commas → `%2C`); most place names round-trip fine unencoded but encode anything with special characters.
- Each option gets its own link built from *that option's* stops — don't reuse one link across options, the whole point is the map matches what's actually being proposed.
- Present it as a plain markdown link the user can click: `[Open in Google Maps](<url>)`.

If a route conflicts with a stated constraint (winding roads + motion sickness, drive-day exceeding the limit), don't silently drop it — offer it with the conflict named, so the user can override with eyes open.

Keep this conversational: propose, don't just enumerate. Ask which one lands, or if none do.

## Step 4: Write the choice back

**Running outside the repo** (per Step 1.4, no trip folder exists) — there's nothing to write to. Once the user decides, emit the same Route, Food, and Open items content below as a single fenced markdown block, formatted exactly as it would be written into `trip.md`, and hand it to the user: "Save this into your trip-planner folder as `trips/<trip-name>/trip.md` (or attach it next time) and the rest of the planning skills will pick up where this left off." Skip the "update the file" instructions below and go straight to Step 5.

Same turn the user decides, update `trips/<trip-name>/trip.md`:

**Route section** — chosen route with per-day segments, tolls, and a decision date, in the `trip-v1` format (see `trips/example-trip/trip.md`):

```markdown
## Route

**Chosen:** <road/route description>. ~<total> mi total, ~<total drive time>. Tolls: ~$<amount> (<which roads>) / no tolls.
- Map: [Open in Google Maps](<url from Step 3, rebuilt with the chosen option's actual waypoints>)
- Day 1: <A> → <B> (<drive time>) — decided <date>
- Day 2: <B> → <C> (<drive time>) — decided <date>
- Notable stop: [<name>](<maps place link>) — <one-line fact> (only for scenic choices)
- Rejected: <other option> (<one-line reason, e.g. "faster by 1.5h, but Maya vetoed the monotony">
- Rejected waypoint: <name> (<one-line reason, e.g. "shortlisted for Day 2 but user preferred the caverns for more hands-on kid appeal">
```

- Log every rejected option with its actual reason (faster-but-boring, deadline miss, exceeds driving limit, tolls, etc.) — this stops it from being re-proposed in a later session.
- Log every rejected waypoint candidate the same way, right next to the stop that won — this is what stops the same slot from re-rolling a different town next session.
- If a chosen segment still conflicts with a soft constraint (e.g. a scenic road despite motion sickness), note the mitigation next to it ("stops every 90 min for Maya").

**Food section** — pre-seed with the food picks surfaced while comparing route options (Step 3), so the slot isn't left as a bare placeholder when a decent candidate already came up:

```markdown
## Food

- Day 1 lunch (~<location>, <time>): _candidate: [<name>](<maps place link>) — <one-line why>, to confirm_
```

Mark these `_candidate_`, not `_Chosen_` — they've only had the lightweight pass from Step 3, not food-scout's full filter/rank. food-scout treats an existing candidate as a head start, not a finished pick, when it later scouts that slot.

**Open items** — add entries handing off to the next phases:

```markdown
## Open items

- [ ] Book stay: <city>, night of <date>
- [ ] Scout food: Day <n> <meal> (~<location>, <time>) — candidate on file, confirm or replace
```

One stay item per overnight stop, one food item per meal slot worth scouting (skip meals the user says they'll wing).

**Budget section** — add or update the fuel-estimate line using the route's actual total mileage and the vehicle's mpg from trip.md Parameters, stating the gas-price assumption inline since it's an estimate, not a quote:

```markdown
## Budget

- Fuel est.: <total> mi / <mpg> mpg × $<assumed price/gal> ≈ $<total>
```

Leave any other Budget lines (lodging cap, food/day) untouched — this skill only owns the fuel line; stay-scout owns lodging, and food/day is a user-entered planning number no skill touches.

- Update `Log` with a dated entry: `<date> — route chosen, day segments drafted (session N)`.
- If this is a new trip, set `status: planning` in the frontmatter if not already.

## Step 5: Hand off

Close by naming what's next: "Route's set — want to lock in stays next, or scout food along the way?" Don't start stays/food yourself; that's the next phase per CLAUDE.md's planning order (travelers → route → stays/food → itinerary).

## Notes for other skills

- **replanner** calls back into this logic to recompute only the affected segments after a disruption — it should reuse this step's constraint-deriving and option-proposing behavior rather than re-implementing it, then apply its own minimal-diff write-back.
- **food-scout** picks up any `_candidate_` markers this skill seeds in the Food section and runs its own full filter/rank pass before promoting one to `Chosen` — this skill's food picks are a lightweight comparison aid, not a substitute for that pass.
