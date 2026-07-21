# Trip Planner

A Claude-powered trip planning workspace. Clone it, open it with Claude Code (or Cowork), and say "plan a road trip to Nashville" — Claude handles the rest using the skills bundled in this repo.

License: MIT (see `LICENSE`).

## ⚠️ Before anything else: keep this repo PRIVATE

`profiles/travelers.md` will contain personal information about your family — allergies, medical constraints, ages. Git history is forever, and a public repo publishes it to the world.

- If you got here via GitHub's **"Use this template"** button: make sure you selected **Private** when creating your copy.
- If you forked or cloned: push only to a **private** repository.

## Getting started

1. Copy this repo (template button or clone) and open the folder with Claude Code or Cowork.
2. Once, right after cloning: run `git config merge.ours.driver true`. This tells git to honor the `.gitattributes` rule that keeps `git pull upstream main` from ever overwriting your personal data — see "What lives where" below.
3. Say what you want: *"plan a road trip from Chicago to Denver in August."*
4. The first time, Claude will notice `profiles/travelers.md` is still a blank template (or missing) and offer a two-minute interview to fill it in (or you can fill it in by hand — the template explains each field).
5. Claude creates a folder for your trip under `trips/` and plans inside it. Everything is a plain markdown file you can read, edit, and version.

Returning later? Just open the folder and say "continue the Nashville trip." Claude reads the state from the files — you never repeat yourself.

## What lives where

| Path | What it is | Who edits it |
|---|---|---|
| `profiles/travelers.md` | Who travels with you: dietary needs, preferences, constraints. Shared across all trips. | You (by hand or via Claude) |
| `trips/<trip-name>/trip.md` | One file per trip: route, stops, stays, food, budget. | Claude (and you, freely) |
| `trips/example-trip/` | A worked example showing the trip file format. Safe to delete. | Nobody — it's documentation |
| `CLAUDE.md` | Instructions Claude reads at the start of every session. | Template maintainer |
| `.claude/skills/` | The planning skills (traveler interview, route planner, food scout, ...), including the blank `travelers.template.md` that seeds a fresh `profiles/travelers.md`. | Template maintainer |

**Rule of thumb:** your data lives in `profiles/` and `trips/` (except `trips/example-trip/`); the machinery lives everywhere else. A `.gitattributes` in this repo marks `profiles/**` and `trips/**` as `merge=ours`, so `git pull upstream main` keeps your local copies instead of trying to merge upstream's, and your hand-edits are safe — **provided you ran the one-time `git config merge.ours.driver true` from Getting started.** Git ignores `merge=ours` without that config; you never need to touch `.gitattributes` itself, but that one command is not optional.

## Using without Claude Code

The files work in the claude.ai chat app too: install the skills from `.claude/skills/` individually. Get packaged `.skill` files either from this repo's [Releases page](../../releases) (each release auto-attaches one `.skill` file per skill) or by running `scripts/package-skills.sh` yourself, which writes them to `dist/`. Open a `.skill` file and click Save skill, then attach `profiles/travelers.md` and your `trip.md` to any conversation. Same planning, slightly more file-carrying.

## Updating the skills

If you copied this from an upstream template, pull its changes to get skill improvements:

```
git remote add upstream <template-repo-url>   # once
git config merge.ours.driver true             # once — tells git to honor merge=ours below
git pull upstream main                        # whenever
```

Skills never write to `.claude/`, and `.gitattributes` marks `profiles/**` and `trips/**` (besides the example trip) as `merge=ours`, so pulls never touch your data — even if upstream also modifies those paths, your local version wins.
