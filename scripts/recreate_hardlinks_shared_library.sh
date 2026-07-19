#!/bin/bash
set -euo pipefail

REPO_NAME="PyScript-Shared-Library"

find_ha_config() {
  if [ -d "/config" ] && [ -f "/config/configuration.yaml" ]; then
    printf '%s\n' "/config"
    return 0
  fi

  while IFS= read -r ha_file; do
    local candidate
    candidate=$(dirname "$ha_file")
    if [ -f "$candidate/configuration.yaml" ]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done < <(find /mnt -type f -name ".HA_VERSION" 2>/dev/null)

  return 1
}

HA_CONFIG=$(find_ha_config) || {
  echo "Could not find the Home Assistant config directory."
  exit 1
}

LIBRARY_DIR="$HA_CONFIG/$REPO_NAME"
MODULE_SOURCE="$LIBRARY_DIR/pyscript/modules/dezito_pyscript"
MODULE_TARGET="$HA_CONFIG/pyscript/modules/dezito_pyscript"
MANIFEST_FILE="$HA_CONFIG/.pyscript_shared_library_manifest"

if [ ! -d "$MODULE_SOURCE" ]; then
  echo "Missing library directory: $MODULE_SOURCE"
  echo "Run update_shared_library.sh first."
  exit 1
fi

mkdir -p "$MODULE_TARGET"

if [ -f "$MANIFEST_FILE" ]; then
  while IFS= read -r relative_path; do
    [ -n "$relative_path" ] || continue
    rm -f "$MODULE_TARGET/$relative_path"
  done < "$MANIFEST_FILE"
fi

TEMP_MANIFEST=$(mktemp)
trap 'rm -f "$TEMP_MANIFEST"' EXIT

while IFS= read -r -d '' source_file; do
  relative_path="${source_file#$MODULE_SOURCE/}"
  target_file="$MODULE_TARGET/$relative_path"

  mkdir -p "$(dirname "$target_file")"
  ln -f "$source_file" "$target_file"
  printf '%s\n' "$relative_path" >> "$TEMP_MANIFEST"
done < <(find "$MODULE_SOURCE" -type f -print0)

sort -u "$TEMP_MANIFEST" > "$MANIFEST_FILE"
find "$MODULE_TARGET" -depth -type d -empty -delete 2>/dev/null || true

echo "Shared library hardlinks recreated in: $MODULE_TARGET"