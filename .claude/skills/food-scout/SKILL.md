---
name: food-scout
description: Recommend 2-3 vetted meal options grounded in profiles/travelers.md. Trigger when the user asks about food, restaurants, or where to eat for a trip or location ("where should we eat tonight in Denver"), when a planning phase reaches food scouting (travelers -> route -> stays/food -> itinerary), or when trips/<trip>/trip.md has a food item marked "_to scout_" or "_candidate: ..._" (a lightweight pick route-planner seeded while comparing routes). Filters out anything violating a hard constraint (allergy, medical, religious dietary law), ranks survivors by soft preferences, and explains why each pick fits. Works standalone with no active trip file too.
---

# Food scout

This skill recommends where to eat, filtered through who's actually at the table.

## Step 1: Read the profile first

Read `profiles/travelers.md` before recommending anything. If it's missing or `status: template`, invoke the **traveler-profiles** skill first — don't guess at constraints or ask ad hoc questions this file is meant to answer.

If there's an active trip (`trips/<trip>/trip.md`), read it too: the food slot's location, arrival time, and any notes ("Day 1 lunch — ~Iowa City, 12:30 — GF-safe for Maya"). If there's no trip file, that's fine — answer in-conversation without inventing a trip folder (see Step 5).

If the slot already carries a `_candidate: <name> — ..., to confirm_` marker (route-planner seeds these while comparing route options), treat it as a head start, not a finished pick — it's only had a lightweight one-line pass, not this skill's full filter/rank. Run the full two-pass process below; if the candidate survives and still ranks well, say so and promote it to `Chosen` rather than silently re-searching from zero.

## Step 2: Filter, then rank

This is a strict two-pass process — never blend the passes:

1. **Hard-constraint filter.** Drop any option that violates a hard constraint for *any* traveler eating — allergy, medical need, religious dietary law, strict vegetarian/vegan. A violating option never appears, not even as a "backup" or "if you're feeling adventurous" aside. If a cuisine can't reliably satisfy a hard constraint (e.g. a ramen shop and a shellfish allergy — broth cross-contact risk), it's out.
2. **Soft-preference ranking.** Among what survives, rank by the party's soft preferences (favorite cuisines, budget comfort, "prefers healthier options," adventurousness). Every recommendation should name which soft preference it satisfies, not just that it's "good" — e.g. "dedicated GF fryer, so cross-contact isn't a concern" or "counter seating, good for a fast lunch stop."

## Step 3: Presentation format

Every recommendation, in every context (chat, trip file, standalone), follows this shape:

```markdown
**<Name>** $$ — ⭐ 4.5 (Google reviews)
[View on Google Maps](<maps link>) · [Website](<url>, if found)
Why it fits: <soft preference it satisfies>
Dishes to try: <dish 1>, <dish 2>, <dish 3> — <one clause on why these suit the party's palate>
```

- **Price:** `$`–`$$$$` right after the name, matching Google's price-level convention for that listing.
- **Rating:** star count and review source right after the price (e.g. "⭐ 4.6 (Google reviews, 1.2k)"). If you can't confirm a real rating, say "rating unavailable" rather than inventing one.
- **Dishes:** pull 2-3 actual menu items (from the restaurant's posted menu, not generic guesses) that suit the party's palate — steer toward soft preferences and away from anything close to a hard-constraint edge, and say briefly why each pick fits (e.g. "no shared fryer with meat dishes," "the one dedicated GF noodle option").
- **Hyperlink — every pick, no exceptions.** Include a Google Maps place link built from the name and city/address, no API key needed: `https://www.google.com/maps/search/?api=1&query=<url-encoded "Name, City, State">`. This both gives the user a clickable place *and* is the same link format that puts a pin on a map. If you found the restaurant's actual website during research, add it too (`· [Website](<url>)`); if not, the Maps link alone is enough — never fabricate a website URL.

## Step 3b: Mark it on the trip's route map

If this food slot belongs to an active trip whose Route section already has a `Map:` link (route-planner writes these — see that skill's "Map links" step), add the chosen pick as a waypoint in that same Google Maps URL when you write the Chosen pick back, so the restaurant shows up as an actual pin on the day's route map instead of only existing as a separate link. Update the Route section's `Map:` line in the same turn you update Food — don't leave the two out of sync.

If there's no Route/Map yet (standalone "where should we eat tonight" ask, or the route isn't decided), skip this — the standalone place link from Step 3 is enough.

## Step 4: Respect the privacy rule

Never include a traveler's name or medical condition in a web search — search by generic dietary/cuisine terms only. Search "gluten-free restaurants Memphis" or "vegetarian restaurants no eggs Nashville" — never "restaurants for Maya who has celiac disease." This rule holds regardless of where this skill is running (in a workspace, it's also spelled out in CLAUDE.md Boundaries) — it's not a style preference.

## Step 5: Check timing

If there's a slot with an arrival time, confirm the option is actually open then — a great dinner spot is useless for a 12:30 lunch stop if it opens at 5pm. Flag this explicitly if you can't verify hours.

## Step 6: Write back (or don't)

**With an active trip file** — same turn the recommendation lands, update the trip's Food section:

```markdown
## Food

- Day 1 lunch (~Iowa City, 12:30): **Chosen: <name>** $$ — ⭐ 4.6 (Google reviews) — GF-safe (dedicated fryer), fits Maya's preference for light lunches
  - [View on Google Maps](<maps link>) · [Website](<url>, if found)
  - Dishes to try: <dish 1>, <dish 2>
  - Rejected: <name> — no confirmed GF-safe prep
```

Record rejected candidates with the reason so they aren't re-surfaced next session. If the user hasn't picked yet, list 2-3 candidates under the slot instead of "Chosen," each still carrying its price, rating, and dish picks.

**Without an active trip file** (standalone "where should we eat tonight" ask) — answer directly in conversation. Don't create a trip folder or trip.md just to hold a one-off recommendation; only write to a trip file if one already exists for this context.

## Step 7: Hand off

If this was part of a food-scouting phase across multiple trip days, note what's left ("Day 2 dinner in North Platte still needs scouting") so the next session or itinerary-builder pass knows what's open.

## How this differs from a generic restaurant search

The value here is entirely the two-pass filter/rank — a plain web search can't tell a dedicated-fryer GF spot from one that just has a GF-labeled menu item. If travelers.md doesn't have enough detail to make that call confidently, say so and ask the one clarifying question that matters (e.g. "is Maya's allergy severe enough that cross-contact matters, or just an ingestion issue?") rather than guessing.
