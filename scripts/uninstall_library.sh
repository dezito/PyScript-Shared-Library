#!/bin/bash
set -euo pipefail

REPO_NAME="PyScript-Shared-Library"
REMOVE_REPOSITORY=false

if [ "${1:-}" = "--remove-repository" ]; then
  REMOVE_REPOSITORY=true
fi

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
MODULE_TARGET="$HA_CONFIG/pyscript/modules"
MANIFEST_FILE="$HA_CONFIG/.pyscript_shared_library_manifest"

if [ -f "$MANIFEST_FILE" ]; then
  echo "Removing shared library modules..."

  while IFS= read -r relative_path; do
    [ -n "$relative_path" ] || continue

    target_file="$MODULE_TARGET/$relative_path"
    if [ -f "$target_file" ] || [ -L "$target_file" ]; then
      rm -f "$target_file"
      echo "Removed: $target_file"
    fi
  done < "$MANIFEST_FILE"

  rm -f "$MANIFEST_FILE"
else
  echo "No shared library manifest found. No module files were removed."
fi

if [ -d "$MODULE_TARGET" ]; then
  find "$MODULE_TARGET" -depth -type d -empty -delete 2>/dev/null || true
fi

if [ "$REMOVE_REPOSITORY" = true ]; then
  if [ -d "$LIBRARY_DIR" ]; then
    rm -rf "$LIBRARY_DIR"
    echo "Removed repository: $LIBRARY_DIR"
  fi
else
  echo "Repository retained: $LIBRARY_DIR"
  echo "Use --remove-repository to remove it as well."
fi

echo "PyScript Shared Library uninstalled."