#!/usr/bin/env bash
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo "$(pwd)")"
cd "$ROOT"

VERIFY=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --verify) VERIFY=true; shift ;;
    --help|-h) echo "Usage: $0 [--verify]"; exit 0 ;;
    *) echo "Unknown arg: $1"; exit 2 ;;
  esac
done

echo "==> Running FRB codegen (make codegen)"
make codegen

echo "==> Building native crates (make build-native)"
make build-native

GENERATED_DIR="lib/bridge"
if [ ! -d "$GENERATED_DIR" ]; then
  echo "❌ Expected generated bindings directory not found: $GENERATED_DIR"
  exit 1
fi

echo "✅ Codegen produced files in $GENERATED_DIR:"
find "$GENERATED_DIR" -maxdepth 2 -type f -print || true

if [ "$VERIFY" = true ]; then
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "==> Verifying generated bindings are up-to-date with repository (HEAD)"
    if ! git diff --no-ext-diff --quiet HEAD -- "$GENERATED_DIR"; then
      echo "❌ Generated bindings differ from committed files in $GENERATED_DIR."
      echo ""
      echo "To update bindings locally:"
      echo "  ./scripts/generate_bindings.sh"
      echo "  git add $GENERATED_DIR"
      echo "  git commit -m \"chore: regenerate flutter-rust-bridge bindings\""
      echo ""
      exit 2
    fi
    echo "✅ Generated bindings match repository HEAD."
  else
    echo "⚠️ Not a git repository — skipping verify step."
  fi
fi

echo "All done."