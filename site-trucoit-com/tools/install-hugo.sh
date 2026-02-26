#!/usr/bin/env bash
set -euo pipefail

HUGO_VERSION="${1:-}"

if [ -z "$HUGO_VERSION" ]; then
  echo "Error: HUGO_VERSION not provided"
  exit 1
fi

if [ "$(uname -s)" != "Linux" ] || [ "$(uname -m)" != "x86_64" ]; then
  echo "Unsupported system: Only Linux AMD64 is supported for now."
  exit 1
fi

if ! command -v dpkg &> /dev/null; then
  echo "Unsupported system: Only Debian derivatives (.deb) are supported."
  exit 1
fi

TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

cd "$TEMP_DIR"

curl -s "https://api.github.com/repos/gohugoio/hugo/releases/tags/$HUGO_VERSION" | jq '.assets[] | select(.name | contains("hugo_extended_") and contains("_linux-amd64.deb") and (contains("withdeploy") | not))' | jq -r .browser_download_url | xargs wget -qO hugo.deb

curl -s "https://api.github.com/repos/gohugoio/hugo/releases/tags/$HUGO_VERSION" | jq '.assets[] | select(.name | contains("_checksums.txt"))' | jq -r .browser_download_url | xargs wget -qO checksums.txt

if ! grep -q "$(sha256sum hugo.deb | awk '{print $1}')" checksums.txt; then
  echo "Checksum does not match! Aborting..."
  exit 1
fi

sudo dpkg -i hugo.deb
echo "Hugo $HUGO_VERSION installed successfully"
