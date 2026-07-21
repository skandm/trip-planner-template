#!/usr/bin/env bash
# Lint every .claude/skills/<name>/ directory for the structural conventions that
# claude.ai, Claude Code, and scripts/package-skills.sh all rely on:
#   1. SKILL.md exists.
#   2. SKILL.md starts with YAML frontmatter (--- on the first line) that
#      contains a `name:` field and a `description:` field.
#   3. Frontmatter `name:` matches the directory's basename exactly.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
skills_dir="$repo_root/.claude/skills"

if [[ ! -d "$skills_dir" ]]; then
  echo "lint-skills: no such directory: $skills_dir" >&2
  exit 1
fi

fail=0

shopt -s nullglob
for skill_path in "$skills_dir"/*/; do
  name="$(basename "$skill_path")"
  skill_file="$skill_path/SKILL.md"

  if [[ ! -f "$skill_file" ]]; then
    echo "FAIL $name: missing SKILL.md" >&2
    fail=1
    continue
  fi

  first_line="$(sed -n '1p' "$skill_file")"
  if [[ "$first_line" != "---" ]]; then
    echo "FAIL $name: SKILL.md does not start with '---' frontmatter delimiter" >&2
    fail=1
    continue
  fi

  # Frontmatter body is everything between the first '---' line and the next
  # '---' line (i.e. lines 2..closing-delimiter-1).
  closing_line="$(awk '/^---$/{n++; if (n==2) {print NR; exit}}' "$skill_file")"
  if [[ -z "$closing_line" ]]; then
    echo "FAIL $name: SKILL.md frontmatter has no closing '---' delimiter" >&2
    fail=1
    continue
  fi

  frontmatter="$(sed -n "2,$((closing_line - 1))p" "$skill_file")"

  name_line="$(printf '%s\n' "$frontmatter" | grep -m1 '^name:[[:space:]]*' || true)"
  if [[ -z "$name_line" ]]; then
    echo "FAIL $name: SKILL.md frontmatter is missing a 'name:' field" >&2
    fail=1
    continue
  fi

  description_line="$(printf '%s\n' "$frontmatter" | grep -m1 '^description:[[:space:]]*' || true)"
  if [[ -z "$description_line" ]]; then
    echo "FAIL $name: SKILL.md frontmatter is missing a 'description:' field" >&2
    fail=1
    continue
  fi

  # Extract the name value: strip the "name:" prefix, surrounding whitespace,
  # and optional matching quotes.
  frontmatter_name="$(printf '%s' "$name_line" | sed -E 's/^name:[[:space:]]*//' | sed -E 's/[[:space:]]+$//' | sed -E "s/^\"(.*)\"\$/\1/; s/^'(.*)'\$/\1/")"

  if [[ "$frontmatter_name" != "$name" ]]; then
    echo "FAIL $name: frontmatter name '$frontmatter_name' does not match directory name '$name'" >&2
    fail=1
    continue
  fi

  echo "OK   $name"
done

if [[ "$fail" -ne 0 ]]; then
  echo "lint-skills: one or more skill directories failed structural checks" >&2
  exit 1
fi

echo "lint-skills: all skill directories under .claude/skills/ passed structural checks"
