#!/bin/bash
set -e

CASK_PATH="$1"
REPO="$2"
APP_NAME="$3"
INCLUDE_PRERELEASE="${4:-false}"
SHA_TYPE="${5:-single}"

if [ -z "$CASK_PATH" ] || [ -z "$REPO" ] || [ -z "$APP_NAME" ]; then
  echo "Usage: $0 CASK_PATH REPO APP_NAME [INCLUDE_PRERELEASE] [SHA_TYPE]"
  exit 1
fi

if [ ! -f "$CASK_PATH" ]; then
  echo "Cask file $CASK_PATH not found. Skipping."
  exit 0
fi

# Fetch releases
RELEASES_DATA=$(curl -s -H "Authorization: token $GH_PAT" "https://api.github.com/repos/$REPO/releases")

get_latest_tag() {
  local json="$1"
  local include_pre="$2"
  if command -v jq >/dev/null 2>&1; then
    if [ "$include_pre" = "true" ]; then
      echo "$json" | jq -r '.[0].tag_name'
    else
      echo "$json" | jq -r '[.[] | select(.prerelease == false)][0].tag_name'
    fi
  else
    echo "$json" | grep -m 1 '"tag_name":' | sed -E 's/.*"tag_name": "([^"]+)".*/\1/'
  fi
}

LATEST_TAG=$(get_latest_tag "$RELEASES_DATA" "$INCLUDE_PRERELEASE")
LATEST_VERSION=$(echo "$LATEST_TAG" | sed -E 's/^(v|release-|build-)//')

CURRENT_VERSION=$(grep -oP 'version ["'"'"']\K[^"'"'"']+' "$CASK_PATH" || echo "not-found")
if [ "$CURRENT_VERSION" = "$LATEST_VERSION" ]; then
  echo "$APP_NAME is already up to date."
  exit 0
fi

echo "Updating $APP_NAME to version $LATEST_VERSION..."

# Update version
sed -i.bak -E "s/version [\"'].*[\"']/version \"$LATEST_VERSION\"/" "$CASK_PATH"

# SHA256 Handling
TEMP_DIR=$(mktemp -d)
get_filename() { echo "$1" | sed -E 's|.*/([^/]+)$|\1|'; }

# Check if SHA_TYPE is none and if the cask has :no_check
IS_NO_CHECK=$(grep -c "sha256 :no_check" "$CASK_PATH" || true)

if [ "$SHA_TYPE" = "none" ]; then
  echo "Preserving existing SHA configuration as 'none' was specified."
  # If no_check doesn't exist but SHA_TYPE is none, we should add it
  if [ "$IS_NO_CHECK" -eq 0 ]; then
    sed -i.bak -E "/^  version/ a\\
  sha256 :no_check
" "$CASK_PATH"
  fi
else
  # Remove any existing sha256 (handles :no_check, single, and multi-arch)
  sed -i.bak '/^\s*sha256 /d' "$CASK_PATH"

  if [ "$SHA_TYPE" = "dual" ]; then
    ARM_URL=$(echo "$RELEASES_DATA" | jq -r --arg TAG "$LATEST_TAG" '[.[] | select(.tag_name == $TAG)][0].assets[] | select(.name | test("arm|arm64")) | .browser_download_url' | head -1)
    INTEL_URL=$(echo "$RELEASES_DATA" | jq -r --arg TAG "$LATEST_TAG" '[.[] | select(.tag_name == $TAG)][0].assets[] | select(.name | test("intel|x86_64|amd64")) | .browser_download_url' | head -1)

    if [ -z "$ARM_URL" ] || [ -z "$INTEL_URL" ]; then
      echo "❌ ARM or Intel asset not found for $APP_NAME"
      rm -rf "$TEMP_DIR"
      exit 1
    fi

    ARM_FILE="$TEMP_DIR/$(get_filename "$ARM_URL")"
    INTEL_FILE="$TEMP_DIR/$(get_filename "$INTEL_URL")"

    curl -L "$ARM_URL" -o "$ARM_FILE"
    curl -L "$INTEL_URL" -o "$INTEL_FILE"

    ARM_SHA256=$(shasum -a 256 "$ARM_FILE" | awk '{ print $1 }')
    INTEL_SHA256=$(shasum -a 256 "$INTEL_FILE" | awk '{ print $1 }')

    sed -i.bak -E "/^  version/ a\\
  sha256 arm:   \"$ARM_SHA256\",\\
         intel: \"$INTEL_SHA256\"
" "$CASK_PATH"

  elif [ "$SHA_TYPE" = "single" ]; then
    UNIVERSAL_URL=$(echo "$RELEASES_DATA" | jq -r --arg TAG "$LATEST_TAG" '[.[] | select(.tag_name == $TAG)][0].assets[0].browser_download_url')
    UNIVERSAL_FILE="$TEMP_DIR/$(get_filename "$UNIVERSAL_URL")"
    curl -L "$UNIVERSAL_URL" -o "$UNIVERSAL_FILE"
    UNIVERSAL_SHA256=$(shasum -a 256 "$UNIVERSAL_FILE" | awk '{ print $1 }')

    sed -i.bak -E "/^  version/ a\\
  sha256 \"$UNIVERSAL_SHA256\"
" "$CASK_PATH"
  fi
fi

rm -rf "$TEMP_DIR"
rm -f "$CASK_PATH.bak"


# Git operations
git add "$CASK_PATH"
git commit -S -m "$APP_NAME: v$LATEST_VERSION"
git push origin main

echo "Done with $APP_NAME"
