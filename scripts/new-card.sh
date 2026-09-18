#!/usr/bin/env bash
# Scaffold a new rule card from the template.
# Usage: scripts/new-card.sh <domain> <slug>
#   e.g. scripts/new-card.sh auth/common social-login-ordering
set -euo pipefail
cd "$(dirname "$0")/.."

dom="${1:-}"; slug="${2:-}"
[ -z "$dom" ] || [ -z "$slug" ] && { echo "usage: scripts/new-card.sh <domain> <slug>"; exit 1; }

dir="domains/$dom"
file="$dir/$slug.md"
[ -e "$file" ] && { echo "exists: $file"; exit 1; }
mkdir -p "$dir"

# id = domain-with-dashes + slug, deduped
id="$(echo "$dom" | tr '/' '-')-$slug"
today="$(date +%Y-%m-%d)"

sed -e "s|^id:.*|id: $id|" \
    -e "s|^domain:.*|domain: $dom|" \
    -e "s|^created:.*|created: $today|" \
    -e "s|^updated:.*|updated: $today|" \
    templates/rule-card.md > "$file"

echo "Created $file (id: $id)"
echo "Edit it, then run scripts/reindex.sh"
