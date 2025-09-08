### Branches
Create from `main`: `feat/<topic>`, `fix/<topic>`, `chore/<topic>`.

### Commits & PRs
- Use Conventional Commit **PR titles** (e.g., `feat: add saved places`).
- Squash merge only. Keep PRs small when possible.

### Release (human gate)
1) When `main` is green, open a PR that bumps `version:` in `pubspec.yaml`.
2) Merge it after review.
3) Run **Actions → Cut Release** with the matching version (or push tag `vX.Y.Z` manually).
4) Artifacts and GitHub Release are created automatically.
