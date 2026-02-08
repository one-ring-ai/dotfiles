#!/usr/bin/env bash

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
readonly SOURCE_PATH="$REPO_ROOT/.config/opencode/setup.sh"
readonly OUTPUT_DIR="$REPO_ROOT/artifacts"
readonly OUTPUT_FILE="$OUTPUT_DIR/setup.sh"
readonly CHECKSUM_FILE="$OUTPUT_DIR/setup.sh.sha256"

if [ ! -f "$SOURCE_PATH" ]; then
    echo "Error: Source file not found: $SOURCE_PATH" >&2
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

cp "$SOURCE_PATH" "$OUTPUT_FILE"

if [ ! -s "$OUTPUT_FILE" ]; then
    echo "Error: Output file is empty or missing: $OUTPUT_FILE" >&2
    exit 1
fi

cd "$OUTPUT_DIR"
sha256sum setup.sh > setup.sh.sha256

if ! sha256sum --check setup.sh.sha256 >/dev/null 2>&1; then
    echo "Error: Checksum verification failed" >&2
    exit 1
fi
