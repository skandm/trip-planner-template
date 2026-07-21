#!/usr/bin/env bash
# Package each .claude/skills/<name>/ directory into a distributable dist/<name>.skill file.
# A .skill file is just a zip of the skill directory's contents (SKILL.md + any assets),
# rooted at the top level of the archive so claude.ai's "Save skill" import finds SKILL.md directly.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
skills_dir="$repo_root/.claude/skills"
dist_dir="$repo_root/dist"

rm -rf "$dist_dir"
mkdir -p "$dist_dir"

shopt -s nullglob
for skill_path in "$skills_dir"/*/; do
  name="$(basename "$skill_path")"

  if [[ ! -f "$skill_path/SKILL.md" ]]; then
    echo "skipping $name: no SKILL.md" >&2
    continue
  fi

  out="$dist_dir/$name.skill"
  (cd "$skill_path" && zip -q -r "$out" . -x '.*' -x '*/.*')
  echo "packaged $name -> ${out#"$repo_root"/}"
done
