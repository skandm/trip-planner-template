# Itinerary export — style guide

The design contract for every page this skill renders. `itinerary.template.html` implements it; this file explains it so a regenerated or hand-adjusted export doesn't drift. When the template and this guide disagree, fix the template.

## The one rule that prevents unreadable pages

**The page paints its own surface.** All content lives inside `<div class="page">`, which sets both `background: var(--bg)` and `color: var(--ink)`. Never rely on the host's canvas: hosted artifact viewers, embeds, and print engines each supply their own background, and their theme may not match the one your media query detected (a dark-mode OS viewing a light-themed viewer = near-white text on a white canvas — the exact bug this rule exists for). Text and the background it sits on must come from the same token set, guaranteed by sitting on the same element.

## Theming contract

Three layers, in this order, all defined in the template:

1. `:root { … }` — light tokens as custom properties (the default).
2. `@media (prefers-color-scheme: dark) { :root { … } }` — dark tokens on OS signal.
3. `:root[data-theme="light"]` / `:root[data-theme="dark"]` — explicit overrides; artifact viewers stamp this attribute when the user toggles theme, and it must beat the media query in both directions.

Components read tokens only — no literal colors outside the token blocks. A theme is changed by redefining tokens, never by restyling components.

## Tokens

Roles, not colors. Measured WCAG contrast shown against `--bg` / `--rail`.

| Token | Role | Light | Dark | Contrast (light) | Contrast (dark) |
|---|---|---|---|---|---|
| `--bg` | page surface | `#F6F6F2` | `#151B22` | — | — |
| `--rail` | time chips, stay card fill | `#EBEDE4` | `#1D2530` | — | — |
| `--ink` | body content | `#1E242A` | `#EDF0F3` | 14.5 / 13.2 | 15.2 / 13.5 |
| `--subtle` | secondary detail (notes, meta) | `#3C454F` | `#C4CDD6` | 9.0 / 8.2 | 10.8 / 9.6 |
| `--muted` | metadata only (eyebrow, footer) | `#4A545F` | `#A7B1BC` | 7.1 / 6.5 | 8.0 / 7.1 |
| `--accent` | links, day labels, rules | `#2B5A9E` | `#8FB4E8` | 6.3 / 5.8 | 8.1 / 7.3 |
| `--line` | hairline dividers | `#DDDFD7` | `#2B3540` | decorative | decorative |

Hierarchy is three text tiers and no more: content in `--ink`, supporting detail in `--subtle`, metadata in `--muted`. **Never demote a full sentence the reader needs to `--muted`** — if it matters on the road, it's `--ink` or `--subtle`.

Floor for any change: 7:1 for `--ink`/`--subtle`, 4.5:1 for `--muted`/`--accent`, in **both** themes against **both** surfaces. Validate before shipping:

```python
def srgb(c):
    c /= 255
    return c/12.92 if c <= 0.03928 else ((c+0.055)/1.055)**2.4
def lum(h):
    h = h.lstrip('#')
    return 0.2126*srgb(int(h[0:2],16)) + 0.7152*srgb(int(h[2:4],16)) + 0.0722*srgb(int(h[4:6],16))
def contrast(a, b):
    hi, lo = sorted((lum(a), lum(b)), reverse=True)
    return (hi+0.05) / (lo+0.05)
# assert contrast(ink, bg) >= 7, etc. — every text token x both surfaces x both themes
```

## Type scale

Two faces: a serif display (`"Iowan Old Style", Georgia, serif`) for the trip title and day headings only; the system sans stack for everything else. Scale (rem): 2.1 title / 1.3 day heading / 1 body / 0.9375 notes / 0.875 meta + time rail / 0.75 eyebrow + day label (uppercase, 0.12em letter-spacing). Times set `font-variant-numeric: tabular-nums`. Headings get `text-wrap: balance`.

## Layout

- Single column, `max-width: 46rem`, body line-height 1.6.
- Schedule rows are a grid: `4rem` time rail + content (+ `7rem` thumbnail when present). Space with `gap`, not margins.
- The night's stay is a `.stay` card on `--rail` with a 3px `--accent` left border — the only filled card on the page.
- Wide content scrolls in its own `overflow-x: auto` container; the page never scrolls sideways.
- Print (`@media print`): no max-width, `break-inside: avoid` per day, links flatten to ink.

## Images

- Data URIs only — the page must work offline and hosted viewers block external requests. Hotlinks are silent broken squares.
- ~560px wide, JPEG quality ~55, 30–80 KB each; hero + one thumb per notable stop; total page under ~1 MB.
- Freely-licensed sources only (Wikimedia Commons), credits in the footer. No free photo → no photo.
- Every `<img>` has real `alt` text describing the place.

## Verification

Screenshot before shipping — headless Chrome, both themes (stamp `data-theme="dark"` on `<html>` in a copy for the dark pass):

```sh
chrome --headless --disable-gpu --window-size=900,2400 --screenshot=out.png "file://$PWD/itinerary.html"
```

Check: no grey-on-grey paragraphs, time rail legible, links visibly distinct from body text, images not stretched, footer credits present.
