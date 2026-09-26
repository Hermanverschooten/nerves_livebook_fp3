#!/usr/bin/env bash
# Download the workshop models on the HOST, for devices without internet
# access. Copy them to each phone afterwards:
#
#   ./scripts/fetch_models.sh
#   sftp nerves.local <<< $'-mkdir /data/models\nput models/* /data/models/'
#
# Devices with internet access fetch the same files themselves at boot
# (config :nerves_ai, :models in config/config.exs).
#
# Total download: about 670 MB. Re-runs skip files already present.

set -euo pipefail

cd "$(dirname "$0")/.."
DEST="models"
mkdir -p "$DEST"

fetch() {
  local url="$1" name="$2" sha="$3"
  if [ -f "$DEST/$name" ]; then
    printf '  ✓ %s (cached)\n' "$name"
  else
    printf '  ↓ %s\n' "$name"
    curl -fSL -o "$DEST/$name.tmp" "$url"
    mv "$DEST/$name.tmp" "$DEST/$name"
  fi
  echo "$sha  $DEST/$name" | sha256sum --check --quiet
}

echo "Fetching workshop models into $DEST/ …"

fetch \
  "https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf" \
  "tinyllama.gguf" \
  "9fecc3b3cd76bba89d504f29b616eedf7da85b96540e490ca5824d3f7d2776a0"

fetch \
  "https://huggingface.co/TinyLlama/TinyLlama-1.1B-Chat-v1.0/resolve/main/tokenizer.json" \
  "tinyllama-tokenizer.json" \
  "bcd04f0eadf90287bd26e1a183ac487d8a141b09b06aecb7725bbdd343640f2e"

echo "Done."
