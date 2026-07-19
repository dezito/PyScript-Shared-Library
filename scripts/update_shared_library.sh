#!/bin/bash
set -euo pipefail

REPO_URL="https://github.com/dezito/PyScript-Shared-Library.git"
REPO_NAME="PyScript-Shared-Library"
BRANCH="main"

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
MODULE_SOURCE="$LIBRARY_DIR/pyscript/modules"
MODULE_TARGET="$HA_CONFIG/pyscript/modules"
MANIFEST_FILE="$HA_CONFIG/.pyscript_shared_library_manifest"

mkdir -p "$HA_CONFIG/pyscript" "$MODULE_TARGET"

if [ ! -d "$LIBRARY_DIR/.git" ]; then
  echo "Cloning $REPO_URL..."
  git clone --branch "$BRANCH" --single-branch "$REPO_URL" "$LIBRARY_DIR"
else
  echo "Updating shared library..."
  git -C "$LIBRARY_DIR" config --local --add safe.directory "$LIBRARY_DIR" 2>/dev/null || true
  git -C "$LIBRARY_DIR" fetch origin "$BRANCH" --prune
  git -C "$LIBRARY_DIR" checkout -f "$BRANCH"
  git -C "$LIBRARY_DIR" reset --hard "origin/$BRANCH"
  git -C "$LIBRARY_DIR" clean -fd
fi

if [ ! -d "$MODULE_SOURCE" ]; then
  echo "Missing library directory: $MODULE_SOURCE"
  exit 1
fi

# Remove files previously installed by this library. This prevents deleted or
# renamed source files from remaining in Home Assistant after an update.
if [ -f "$MANIFEST_FILE" ]; then
  while IFS= read -r relative_path; do
    [ -n "$relative_path" ] || continue
    target_file="$MODULE_TARGET/$relative_path"
    if [ -f "$target_file" ] || [ -L "$target_file" ]; then
      rm -f "$target_file"
    fi
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

# Remove empty directories left behind by renamed or removed modules.
find "$MODULE_TARGET" -depth -type d -empty -delete 2>/dev/null || true

COMMIT=$(git -C "$LIBRARY_DIR" rev-parse --short HEAD)
echo "PyScript Shared Library updated to latest $BRANCH commit: $COMMIT"
echo "Installed modules in: $MODULE_TARGET"
