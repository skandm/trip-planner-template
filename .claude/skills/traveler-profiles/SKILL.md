---
name: traveler-profiles
description: Interview the user about who is traveling and record the results in profiles/travelers.md — the shared profile file every trip-planning skill reads. Use this skill whenever traveler profiles are missing, incomplete, or stale; whenever profiles/travelers.md still has status template; whenever the user mentions setting up profiles, who's coming on a trip, a new travel companion, or any change to someone's dietary needs, allergies, health constraints, or travel preferences ("Maya's vegetarian now", "we're bringing the kids this time", "my dad is joining and he can't do stairs"). Also use it when another planning task (routes, food, hotels, packing) needs traveler information that isn't on file yet — run this first rather than asking ad-hoc questions.
---

# Traveler profiles

This skill maintains `profiles/travelers.md`: the single file describing who travels, so no other skill — and no future session — ever re-asks. Your job is a short, warm interview (or an update to an existing file), written back in the schema below.

The blank starting point for that file is `travelers.template.md`, packaged alongside this skill. `profiles/travelers.md` itself is never edited by template updates — it's the user's own data, copied from the template once and filled in from there.

## Step 1: Read the current state

Read `profiles/travelers.md`.

- **File missing entirely** (first run in this workspace) → copy `travelers.template.md` (in this skill's folder) to `profiles/travelers.md`, then treat it as the `status: template` case below.
- **Frontmatter says `status: template`** → no profiles exist. Offer the interview: "Before I plan, can I take two minutes to learn who's traveling? You'll never have to answer these again." If the user prefers to fill it by hand, point them at the template's inline instructions and stop.
- **`status: filled`** → profiles exist. Do NOT re-interview. Summarize in one line ("I have Alex — no restrictions — and Maya — gluten-free, celiac. Still right?") and only ask about the specific gap or change that brought you here.
- **Running outside the repo** (e.g. in a claude.ai chat with nothing attached) → ask the user to attach their `travelers.md` if they have one; otherwise run the interview and, at the end, produce the file and hand it to the user with: "Save this — attach it (or keep it in your trip-planner folder as profiles/travelers.md) and every travel skill will use it."

## Step 2: The interview

Per traveler, in this order — the order matters because it front-loads safety:

1. **Name** (and relationship if offered — useful context, never required).
2. **Hard constraints:** "Anything that's a hard no or a health issue — allergies, medical needs, religious dietary rules, strict vegetarian/vegan?" Probe severity for allergies (airborne/cross-contact vs. ingestion) — it changes how strictly food options get filtered.
3. **Soft preferences:** "Strong likes or dislikes? Favorite cuisines, things they won't enjoy, budget comfort for meals?"
4. **Interests:** "What do they actually enjoy doing on a trip — museums, nature and hiking, history, art, nightlife, shopping, live music, theme parks, just wandering? Anything they'd rather skip?"
5. **Logistics:** age if a minor, mobility limits, motion sickness, early bird vs. night owl, whether they can share driving.

Interview style:

- Conversational, not a form march. If the user volunteers everything in one message, extract it and confirm — don't re-ask what they already said.
- One traveler at a time for groups, but offer the shortcut: "same for everyone, or shall we go person by person?"
- **Never guess the tier.** If the user says "vegetarian", ask once whether that's a firm rule or a preference, and whether it's everyone or one person. The hard/soft distinction is the whole value of this file — a mis-tiered allergy is a safety failure, a mis-tiered dislike needlessly kills good options.
- It's fine to record "none" — an explicit "none" tells future skills the question was asked, an empty field doesn't.

## Step 3: Write the file

Write `profiles/travelers.md` in this exact structure (one `###` section per traveler):

```markdown
---
schema: travelers-v1
status: filled
updated: <today's date>
---

# Traveler profiles

### Maya

- **Hard constraints:** gluten-free (celiac — cross-contact matters), shellfish allergy (severe)
- **Soft preferences:** loves Thai and BBQ; prefers light lunches; adventurous eater
- **Interests:** loves museums and live music; not a fan of big-crowd tourist traps; always up for a hike
- **Logistics:** can share driving; night owl
- **Notes:** —
```

Rules:

- Remove the "Person template" section and the instructional comments on first fill; set `status: filled` and `updated`.
- **Confirm before writing** — show a compact summary of what you're about to save. This file is shared across every trip; the user should always see changes to it.
- On updates, edit only what changed and bump `updated`. Preserve the user's own hand-edits and phrasing elsewhere in the file — their edits are authoritative.
- Plain markdown, human-readable, no extra fields beyond the schema. Other skills parse this by section headers and the five bold labels.

## Step 4: Hand off

End by connecting back to what the user actually wanted: "Profiles saved. Now — about that Nashville route…" If this skill was invoked mid-task by another planning need, return to that task immediately; the interview is a detour, not a destination.

## How other skills consume this file

(For reference — this contract is what you're protecting.)

- **Hard constraints filter:** an option violating one never gets recommended, regardless of quality.
- **Soft preferences score:** they shape rankings and get mentioned in recommendations ("has a dedicated GF fryer").
- **Interests drive activity picks:** itinerary-builder uses these to choose anchor activities and stops (a museum day for one traveler, a trailhead for another) and to skip things nobody would enjoy.
- **Logistics inform pacing:** drive-shift planning, kid-friendly stops, motion-sickness-aware routing.
