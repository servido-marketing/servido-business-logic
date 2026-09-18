#!/usr/bin/env bash
# Validate every rule card's frontmatter against the schema.
# Usage: scripts/lint.sh   (exit 0 = all valid, 1 = errors)
set -euo pipefail
cd "$(dirname "$0")/.."

REQUIRED=(id domain title status applies_to tags created)
VALID_STATUS="active superseded deprecated"
errors=0
ids_seen=""

while IFS= read -r f; do
  fm=$(awk 'NR==1&&$0=="---"{f=1;next} f&&$0=="---"{exit} f{print}' "$f")
  if [ -z "$fm" ]; then echo "✗ $f: no frontmatter"; errors=$((errors+1)); continue; fi

  for key in "${REQUIRED[@]}"; do
    echo "$fm" | grep -qE "^${key}:" || { echo "✗ $f: missing '$key'"; errors=$((errors+1)); }
  done

  status=$(echo "$fm" | awk -F': *' '/^status:/{print $2; exit}')
  if [ -n "$status" ] && ! echo " $VALID_STATUS " | grep -q " $status "; then
    echo "✗ $f: invalid status '$status'"; errors=$((errors+1))
  fi

  id=$(echo "$fm" | awk -F': *' '/^id:/{print $2; exit}')
  if [ -n "$id" ]; then
    echo " $ids_seen " | grep -q " $id " && { echo "✗ $f: duplicate id '$id'"; errors=$((errors+1)); }
    ids_seen="$ids_seen $id"
  fi

  # card must physically live under its declared domain
  dom=$(echo "$fm" | awk -F': *' '/^domain:/{print $2; exit}')
  case "$f" in
    domains/$dom/*) : ;;
    *) echo "✗ $f: file location does not match domain '$dom'"; errors=$((errors+1));;
  esac
done < <(find domains -name '*.md' -type f | sort)

if [ "$errors" -gt 0 ]; then echo; echo "FAILED: $errors error(s)"; exit 1; fi
echo "OK: all cards valid"
