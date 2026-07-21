---
name: stay-scout
description: Recommend 2-3 vetted lodging options for a trip night. Trigger when the user asks about hotels, lodging, or where to stay for a trip or location ("where should we stay in Des Moines"), when a planning phase reaches stays (travelers -> route -> stays/food -> itinerary), or when trips/<trip>/trip.md has a Stays entry marked `unbooked` or a `- [ ] Book stay: <city>, night of <date>` open item. Filters out anything violating a hard constraint (mobility limits, party size, a stated hard budget cap, date availability), ranks survivors by soft preferences (price vs. the Budget section's lodging cap, walkability, parking, quiet), and explains why each pick fits. This skill researches; it never marks a stay `booked` on the user's behalf. Works standalone with no active trip file too.
---

# Stay scout

This skill recommends where to stay for a given night, filtered through who's actually sleeping there.

## Step 1: Read state first

Read `profiles/travelers.md` before recommending anything — pull mobility limits (no walk-up-only if someone can't do stairs), kids (crib/rollaway needs, pool as a plus), and budget comfort. If it's missing or `status: template`, invoke the **traveler-profiles** skill first — don't guess at constraints or ask ad hoc questions this file is meant to answer.

If there's an active trip (`trips/<trip>/trip.md`), read it too:

- The **Stays** entry for the night in question — the city, the date, and any stated target (e.g. "walkable to downtown, < $160"). A bare `**unbooked**` with no target means no explicit preference was stated yet; ask if it matters, or proceed on travelers.md alone.
- The **Route** section, for that day's arrival time or drive length — a late arrival from a long drive day makes check-in windows and 24-hour desks worth checking.
- The **Budget** section's lodging cap, if one exists — this is a ranking input (Step 2), not something this skill rewrites; a separate pass owns writing the Budget section.

If there's no trip file, that's fine — answer in-conversation without inventing a trip folder (see Step 6).

## Step 2: Filter, then rank

This is a strict two-pass process — never blend the passes:

1. **Hard filter.** Drop any option that:
   - Violates a mobility limit (e.g. walk-up-only with no elevator, when someone can't do stairs).
   - Doesn't fit the party size (not enough beds/rooms for the group).
   - Exceeds a budget cap the user stated as *hard* (not just the Budget section's soft target — ask if it's unclear which this is).
   - Isn't actually available on the stated date — don't surface a great option that's sold out or closed that night.
2. **Soft rank.** Among what survives, rank by:
   - Price against the Budget section's lodging cap, if one exists.
   - The Stays entry's stated target (walkability, downtown proximity, etc.).
   - Traveler soft preferences from `travelers.md` (quiet, kitchen/kitchenette, breakfast included).
   - **Parking** — call this out per option on a driving trip; a "great downtown boutique hotel" with no parking and a $45/night garage two blocks away is a real tradeoff on a road trip, not a footnote.

Every recommendation should name which target or preference it satisfies, not just that it's "good" — e.g. "two blocks from the target downtown radius, free self-park" or "quietest of the three, but a 10-minute drive out."

## Step 3: Presentation format

Every recommendation, in every context (chat, trip file, standalone), follows this shape:

```markdown
**<Name>** $<price>/night — ⭐ 4.3 (Google reviews)
[View on Google Maps](<maps link>) · [Website](<url>, if found)
Why it fits: <soft preference or target it satisfies>
Parking: <free self-park / paid garage $<amount> / street only, etc.>
```

- **Price:** actual `$<price>/night` for the stated date, not a price tier — lodging prices swing too much by date for `$`–`$$$$` to be useful the way it is for food.
- **Rating:** star count and review source right after the price (e.g. "⭐ 4.3 (Google reviews, 900+)"). If you can't confirm a real rating, say "rating unavailable" rather than inventing one.
- **Hyperlink — every pick, no exceptions.** A Google Maps place link built from the name and city/address, no API key needed: `https://www.google.com/maps/search/?api=1&query=<url-encoded "Name, City, State">`. If you found the property's actual booking site or website during research, add it too (`· [Website](<url>)`); if not, the Maps link alone is enough — never fabricate a website URL.
- **Check-in window:** if the day's drive means a late arrival is likely, note the check-in cutoff or whether it's a 24-hour desk. A great pick with a 10pm front-desk cutoff is a real problem if the drive runs long.

## Step 4: Respect the privacy rule

When searching the web, use **generic terms** — location, dates, and the feature that matters ("hotels near downtown Des Moines free parking," "pet-friendly motels North Platte NE") — never a traveler's name or medical/mobility detail. Search "hotels with ground-floor rooms North Platte," not "hotels for Alex who can't do stairs." This is a hard workspace rule (see CLAUDE.md Boundaries), not a style preference.

## Step 5: Write back, same turn

**With an active trip file** — update the trip's **Stays** entry for that night:

```markdown
## Stays

- Aug 14, Des Moines: **researched** — Chosen: <name>, $<price>/night — ⭐ 4.3 (Google reviews) — 2 blocks from downtown, free self-park
  - [View on Google Maps](<maps link>) · [Website](<url>, if found)
  - Rejected: <name> — no parking on-site, $45/night garage two blocks over
```

- **Status is `researched`, never `booked`** — this skill researches candidates; only the *user* books, and only when they say so ("I booked it," "confirmed the reservation"). If the user reports back that they've actually booked, update the status to `**booked**` and, if it changed, the final price. Never write `booked` on your own inference that a pick "sounds good."
- If the user hasn't picked yet, list 2-3 candidates under the entry instead of "Chosen," each still carrying price, rating, and the fit note — same as food-scout's un-decided state.
- Record rejected candidates with the reason so they aren't re-surfaced next session — same anti-re-proposal convention as route-planner and food-scout.
- **Budget section** — update the lodging line with the actual chosen price against the cap, if a Budget section exists:

```markdown
## Budget

- Lodging cap: $<cap> (<n> nights) — actual: $<sum of chosen prices so far> (<remaining unresearched nights, if any>)
```

  This skill only owns the lodging line — route-planner owns the fuel line, food/day is a user-entered number no skill touches. If there's no Budget section yet, don't create one; that's the user's or route-planner's call.

**Open items** — update the matching line, but don't tick it just because research is done:

```markdown
- [ ] Book stay: Des Moines, night of Aug 14 — researched: <name>, $<price>/night, book directly
```

Only change it to a ticked `- [x] Book stay: <city>, night of <date> — booked: <name>` when the user confirms the booking is actually made. Research and booking are different states — itinerary-builder's blocker check looks for the Stays entry's `unbooked` word, not this checkbox, so moving the entry to `researched` in Step 5's first block is what actually unblocks scheduling; the checkbox is just an honest to-do marker for the user.

**Log** — append a dated entry: `<date> — <city> stay researched, chose <name> (session N)`.

**Without an active trip file** (standalone "where should we stay in Des Moines" ask) — answer directly in conversation. Don't create a trip folder or trip.md just to hold a one-off recommendation; only write to a trip file if one already exists for this context.

## Step 6: Hand off

Name what's left: other nights still marked `unbooked` ("North Platte's still open — want me to scout that one too?"), or, if this was the last unresolved stay, that itinerary-builder's stays blocker is now clear ("Both nights are researched — itinerary-builder can go once food's settled too").

## How this differs from a generic hotel search

The value here is the two-pass filter/rank plus the road-trip-specific details a plain search skips — parking availability, late-check-in windows tied to that day's actual drive length, and mobility fit. If travelers.md doesn't have enough detail to judge a hard constraint confidently (e.g. how severe a mobility limit is), say so and ask the one clarifying question that matters rather than guessing.
