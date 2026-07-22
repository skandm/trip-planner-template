---
name: trip-exporter
description: Render a trip's settled plan into a self-contained, shareable HTML itinerary page. Trigger when the user asks to export, share, print, or "make a page for" a trip ("export the Cape May trip", "make something I can send my mom", "give me a printable itinerary"), or as an offer right after itinerary-builder flips a trip to status ready. Reads trips/<trip>/trip.md as the only content source, scrubs traveler-profile rationale (health, dietary, mobility reasons never leave trip files), writes trips/<trip>/itinerary.html from the bundled template, and optionally publishes it as a private claude.ai Artifact link when that tool is available. The export is derived output — trip.md stays the source of truth and the page is regenerated, never hand-maintained.
---

# Trip exporter

This skill turns a trip's plan into a polished single-file HTML page the user can AirDrop to a co-traveler, print, or share as a link. It renders what `trip.md` has settled — it never plans, picks, or fills gaps.

## Step 1: Read trip.md — and only trip.md

The export is built from `trips/<trip>/trip.md` alone. Do **not** pull content from `profiles/travelers.md` into the page — the export is the one file in a trip folder designed to leave the repo, so it must contain nothing that shouldn't (see Step 2).

If the trip's `status` is still `planning`, say so and ask whether to export anyway. If yes, render the settled parts and mark unsettled slots honestly — a stay still `unbooked` becomes "Lodging: to be decided", a `_to scout_` meal becomes "Restaurant: to be decided". Never invent a placeholder that looks like a decision.

**Running outside the repo** (a claude.ai chat with skills attached): ask the user to attach their `trip.md`, render the page from it, and return the HTML file directly in the conversation. No trip file, nothing to export — say so rather than improvising.

## Step 2: The scrub rule — what may leave the repo

This page gets shared. Apply CLAUDE.md's privacy boundary to its content, not just to web searches:

**Include** — the *what, where, when*:
- Route summary, per-day segments, drive times, the notable-stop facts.
- Chosen stays (name, check-in time, Maps link).
- Chosen food (name, price tier, Maps/website links, dishes-to-try lists).
- The full Itinerary schedule.
- Traveler first names in the header, if the user wants them — co-travelers know each other.

**Exclude** — the *why* and the housekeeping:
- Any constraint rationale: "gluten-free-safe for Maya", "fits the no-eggs rule", "no stairs", motion-sickness notes. The pick stays; the medical/dietary/mobility reason for it is stripped. When a fit note mixes both ("full vegan menu, fits the adventurous preference"), keep only what describes the restaurant itself.
- Rejected options and their reasons.
- Budget, Open items, and Log sections.
- Anything from `profiles/travelers.md`, full stop.

If stripping the rationale would leave a co-traveler without information they genuinely need on the road (e.g. "the vegan section is the safe one to order from"), rephrase it as guidance about the place, never as a fact about a person — "order from the dedicated vegan menu" is fine; "Maya can't have eggs" is not.

## Step 3: Render from the template

Copy the structure and inline CSS of `itinerary.template.html` (next to this file) and fill it with the trip's content. The template implements the design contract in `style-guide.md` (also next to this file) — tokens, type scale, contrast floors, and the theming rules; read it before changing any style, and keep the template's properties intact rather than restyling from scratch:

- **Self-contained** — no external requests of any kind (no CDN fonts, no remote images). It must open from a `file://` path with no network.
- **Both themes** — the template's palette is defined as CSS custom properties with light/dark variants; fill content, don't fork the tokens.
- **Print-friendly** — the template's `@media print` rules keep each day on one page where possible; don't remove them.
- One `.day` section per itinerary day, times in the left rail exactly as `trip.md` states them. Reuse the Maps/website links trip.md already carries. If a chosen stay or stop has none, build the standard Maps search link the other skills use (`https://www.google.com/maps/search/?api=1&query=<url-encoded "Name, City, State">`) — but never fabricate a website URL.
- **Every place is a link, and its metadata rides along.** Chosen restaurants, stays, and stops render with the rating, price tier, and website `trip.md` carries (the template's `.meta` span: `⭐ 4.2 · $$ · Website`). Omit whatever the plan lacks rather than inventing it — an absent rating renders as nothing, not as a guess.
- **Drive legs and the route are links too, even on an unsettled trip.** The header always carries a Route map link (reuse trip.md's `Map:` line, or build a directions link from origin/destination/waypoints: `https://www.google.com/maps/dir/?api=1&origin=<A>&destination=<B>&waypoints=<C%7CD>&travelmode=driving`), and each day's drive row links to directions for that leg's endpoints. Cities and route are known long before restaurants are chosen — a page with zero links because nothing is booked yet is under-built, not honest.
- **Readability is a hard requirement.** The template's contract: body content sets in `--ink`, secondary detail in `--subtle` (≥7:1 contrast), and `--muted` is reserved for true metadata (eyebrow, time rail, footer). Don't demote whole sentences to grey. All content stays inside the `.page` wrapper, which paints its own background — hosted viewers supply their own canvas and theme, and text must never sit on a surface this page doesn't control.
- **Verify before shipping.** Screenshot the rendered file in both themes (style-guide.md's Verification section has the headless-Chrome one-liner) and actually look at it — a page nobody rendered is a page nobody checked.

### Step 3a: Optional photos

Photos make the page dramatically more shareable, but they must be **embedded as data URIs** — the page stays self-contained and hosted artifacts block external requests, so hotlinking silently breaks.

- Source from **freely-licensed repositories** — Wikimedia Commons covers most landmarks, towns, parks, and historic hotels (`https://commons.wikimedia.org/w/api.php?action=query&list=search&srnamespace=6&srsearch=<terms>`, then fetch via `Special:FilePath/<File name>`). Restaurants rarely have free imagery — give them the link-plus-meta treatment instead; never embed a photo scraped from a restaurant's site or Google.
- Resize before embedding (~560px wide, JPEG quality ~55 — `sips` on macOS, `magick`/`convert` elsewhere); each image should land around 30–80 KB. A page over ~1 MB total has too many or too-large images.
- One **hero** (the destination or the night's stay) plus a thumbnail per notable stop is the right density; skip images entirely rather than padding with generic stock.
- Record each photo's author and license from the Commons API (`iiprop=extmetadata`) and render the credits line in the footer — CC-licensed images require attribution. Public-domain/CC0 credits are still good manners.
- No suitable freely-licensed photo → no photo. Never generate, fabricate, or hotlink one.

Write the result to `trips/<trip>/itinerary.html`. If one already exists, overwrite it — this file is always regenerated from `trip.md`, and hand-edits to it are lost by design (the template's footer says so to the reader too).

## Step 4: Optional — publish as a shareable link

If the Artifact tool is available (Claude Code sessions), offer to also publish the page as a claude.ai Artifact: a hosted, default-private link the user can choose to share.

- **Ask before publishing, every time.** Publishing sends the trip's contents to an external service; that's the user's call per trip, not a standing default. The Step 2 scrub must already have run — the artifact gets the same scrubbed content as the local file, never more.
- The Artifact tool supplies its own document skeleton — publish a content-only copy (strip `<!doctype>`, `<html>`, `<head>`, `<body>` wrappers; keep the inline `<style>` and a `<title>`), staged in a scratch directory, not the trip folder.
- Re-exports of the same trip should update the same artifact URL, not mint new links.
- If the tool isn't available (claude.ai, or a restricted session), skip this step without ceremony — the local HTML file is the deliverable.

## Step 5: Log and hand off

Append a dated Log entry to `trip.md`: `<date> — exported itinerary.html` (plus `, published artifact` if Step 4 ran). Don't add an Exports section or otherwise restructure the trip file.

Then tell the user where the file landed and, if anything was rendered as "to be decided", name which skill unblocks it ("Des Moines is still unbooked — stay-scout can settle it, then re-export").

## What this skill never does

- Never alters plan content while exporting — no reordering days, no "improving" times, no adding activities. Rendering is not replanning.
- Never exports `profiles/travelers.md` or any file outside the trip folder.
- Never publishes without an explicit yes in this conversation.
