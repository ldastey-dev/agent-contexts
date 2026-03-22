#!/bin/bash
# deploy.sh — copy agent-contexts templates to a target repository
#
# Usage:
#   ./deploy.sh /path/to/target-repo
#
# This copies:
#   core/        → target repo root     (always-in-context files + .context/index + conventions)
#   standards/   → target .context/standards/  (reference standards)
#   playbooks/   → target .context/playbooks/  (on-demand playbooks)
#
# Then generates:
#   target .claude/skills/  (thin wrappers pointing to playbooks)

set -euo pipefail

TARGET="${1:?Usage: ./deploy.sh /path/to/target-repo}"

if [ ! -d "$TARGET" ]; then
  echo "Error: $TARGET is not a directory"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Deploying agent-contexts to $TARGET"

# Tier 1: always-in-context files → repo root
echo "  Copying core/ → $TARGET/"
cp -r "$SCRIPT_DIR/core/." "$TARGET/"

# Standards → .context/standards/
echo "  Copying standards/ → $TARGET/.context/standards/"
mkdir -p "$TARGET/.context/standards"
cp -r "$SCRIPT_DIR/standards/." "$TARGET/.context/standards/"

# Playbooks → .context/playbooks/
echo "  Copying playbooks/ → $TARGET/.context/playbooks/"
mkdir -p "$TARGET/.context/playbooks"
cp -r "$SCRIPT_DIR/playbooks/." "$TARGET/.context/playbooks/"

# Generate Claude Code skill wrappers from playbooks
echo "  Generating .claude/skills/ wrappers from playbooks..."
mkdir -p "$TARGET/.claude/skills"

generate_skill() {
  local playbook_path="$1"
  local target_dir="$2"
  local rel_path="$3"

  # Extract frontmatter fields
  local name description
  name=$(sed -n 's/^name: *//p' "$playbook_path" | head -1)
  description=$(sed -n 's/^description: *//p' "$playbook_path" | head -1 | sed 's/^"//;s/"$//')

  if [ -z "$name" ] || [ -z "$description" ]; then
    return
  fi

  local skill_dir="$target_dir/$name"
  mkdir -p "$skill_dir"

  cat > "$skill_dir/SKILL.md" << SKILL_EOF
---
name: $name
description: "$description"
allowed-tools: "Read, Grep, Glob, Bash(git *), Write, Edit, Agent"
---

Read and follow \`.context/playbooks/$rel_path\` in full.
SKILL_EOF
}

for playbook in "$SCRIPT_DIR"/playbooks/assess/*.md; do
  filename=$(basename "$playbook")
  generate_skill "$playbook" "$TARGET/.claude/skills" "assess/$filename"
done

for playbook in "$SCRIPT_DIR"/playbooks/review/*.md; do
  filename=$(basename "$playbook")
  name=$(sed -n 's/^name: *//p' "$playbook" | head -1)
  # Review playbooks get read-only tools
  description=$(sed -n 's/^description: *//p' "$playbook" | head -1 | sed 's/^"//;s/"$//')
  if [ -n "$name" ] && [ -n "$description" ]; then
    skill_dir="$TARGET/.claude/skills/$name"
    mkdir -p "$skill_dir"
    cat > "$skill_dir/SKILL.md" << SKILL_EOF
---
name: $name
description: "$description"
allowed-tools: "Read, Grep, Glob, Bash(git *)"
---

Read and follow \`.context/playbooks/review/$filename\` in full.
SKILL_EOF
  fi
done

for playbook in "$SCRIPT_DIR"/playbooks/plan/*.md; do
  filename=$(basename "$playbook")
  generate_skill "$playbook" "$TARGET/.claude/skills" "plan/$filename"
done

for playbook in "$SCRIPT_DIR"/playbooks/refactor/*.md; do
  filename=$(basename "$playbook")
  generate_skill "$playbook" "$TARGET/.claude/skills" "refactor/$filename"
done

echo ""
echo "Done. Next steps:"
echo "  1. Fill in [CONFIGURE] sections in $TARGET/AGENTS.md"
echo "  2. Fill in [CONFIGURE] sections in $TARGET/CLAUDE.md"
echo "  3. Review $TARGET/.claude/settings.json and adjust permissions/hooks"
