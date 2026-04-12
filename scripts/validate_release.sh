#!/usr/bin/env bash
# Usage: validate_release.sh <version>
# Validates pre-conditions for a release build. Exits 1 on any failure.
set -euo pipefail

VERSION="${1:?Usage: validate_release.sh <version>}"

# Ensure we're on main and clean
git fetch origin main --tags
[[ "$(git rev-parse --abbrev-ref HEAD)" == "main" ]] || (echo "❌ Not on main branch" && exit 1)
test -z "$(git status --porcelain)" || (echo "❌ Workspace not clean" && exit 1)

# Validate version format
if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "❌ Invalid version format. Use semantic versioning (e.g., 1.2.3)"
  exit 1
fi

# Check if tag already exists
if git tag | grep -q "^v${VERSION}$"; then
  echo "❌ Tag v${VERSION} already exists"
  exit 1
fi

# Validate pubspec version matches input
PUBSPEC_VERSION=$(grep -E '^version:' pubspec.yaml | awk '{print $2}' | cut -d+ -f1)
if [ "$PUBSPEC_VERSION" != "$VERSION" ]; then
  echo "❌ pubspec.yaml version ($PUBSPEC_VERSION) doesn't match input ($VERSION)"
  echo "💡 Please update pubspec.yaml first"
  exit 1
fi

echo "✅ All validation checks passed"
