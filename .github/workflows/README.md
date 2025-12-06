# GitHub Actions Workflows

This directory contains all GitHub Actions workflows for the nav-e project. These workflows automate our CI/CD pipeline, ensuring code quality, testing, and releases.

## 🔄 Workflow Overview

| Workflow | Trigger | Purpose | Status |
|----------|---------|---------|--------|
| [CI](#ci) | PR/Push to `main`, PR to `release/*` | Code quality & testing | ✅ Active |
| [Release](#release) | Manual dispatch | Create tags, build & publish releases | ✅ Active |
| [PR Title](#pr-title) | PR opened/edited | Enforce conventional commits | ✅ Active |
| [PR Labeler](#pr-labeler) | PR opened/edited | Auto-label PRs | ✅ Active |
| [Stale](#stale) | Weekly schedule | Close stale issues/PRs | ✅ Active |

## 📋 Detailed Workflow Documentation

### CI
**File:** `ci.yml`  
**Triggers:** 
- Pull requests to `main` or `release/*` branches
- Pushes to `main` branch

**What it does:**
1. 🔍 **Format Check** - Ensures code follows Dart formatting standards
2. 📊 **Code Analysis** - Runs `dart analyze` to catch potential issues
3. 🧪 **Tests** - Runs all tests with coverage reporting
4. 🏗️ **Build Check** - Builds debug APK to ensure compilation works

**Requirements:** None (runs automatically)

---

### Release
**File:** `release.yml`  
**Triggers:** Manual workflow dispatch

**What it does:**
1. ✅ **Pre-flight Validation** - Ensures we're on `main` branch with clean workspace
2. 🔍 **Version Validation** - Validates `pubspec.yaml` version matches input and checks semver format
3. 🧪 **Quality Gates** - Runs format check, analysis, and full test suite
4. 📝 **Version Injection** - Creates `lib/core/constants/app_version.dart` with build info
5. �️ **Build Artifacts** - Creates release APK and App Bundle
6. �🏷️ **Tag Creation** - Creates annotated git tag and pushes it
7. � **Release Notes** - Auto-generates changelog and build information
8. 🚀 **GitHub Release** - Creates GitHub release with APK/AAB attachments

**How to use:**
1. Update version in `pubspec.yaml`
2. Commit and push to `main`
3. Go to Actions → Create Release → Run workflow
4. Enter version (e.g., `1.2.0` without `v` prefix)
5. Optionally mark as pre-release
6. Click "Run workflow"

**Features:**
- 🔒 **Comprehensive validation** - Prevents common release mistakes
- ⚡ **All-in-one** - Complete release process in single workflow
- 🎯 **Quality gates** - Tests must pass before release
- 📱 **Multiple formats** - Both APK and AAB files
- � **Auto-changelog** - Generates release notes from commits
- 🏷️ **Pre-release support** - Option for beta/alpha releases

**Requirements:** 
- Must be on `main` branch
- Workspace must be clean (no uncommitted changes)
- Version in `pubspec.yaml` must match input
- All tests must pass

---

### PR Title
**File:** `pr-title.yml`  
**Triggers:** PR opened, edited, or synchronized

**What it does:**
- 📝 **Title Validation** - Ensures PR titles follow conventional commit format

**Allowed types:**
- `feat:` - New features
- `fix:` - Bug fixes  
- `docs:` - Documentation changes
- `style:` - Code style changes
- `refactor:` - Code refactoring
- `perf:` - Performance improvements
- `test:` - Test additions/changes
- `build:` - Build system changes
- `ci:` - CI/CD changes
- `chore:` - Maintenance tasks

**Example valid titles:**
- `feat: add GPS tracking functionality`
- `fix: resolve bluetooth connection issues`
- `docs: update README with installation instructions`

---

### PR Labeler
**File:** `labeler.yml`  
**Triggers:** PR opened, reopened, synchronized, or edited

**What it does:**
- 🏷️ **Auto-labeling** - Automatically applies labels based on changed files
- 📁 **Path-based** - Uses `.github/labeler.yml` configuration

**Label categories:**
- `area:*` - Based on feature areas (map, search, settings, etc.)
- `platform:*` - Based on platform-specific changes
- `area:ci` - CI/CD related changes
- `area:docs` - Documentation changes
- `area:tests` - Test-related changes

---

### Stale
**File:** `stale.yml`  
**Triggers:** Weekly schedule (Mondays at 3 AM UTC)

**What it does:**
- 🕐 **Issue Management** - Marks issues stale after 30 days of inactivity
- 🔒 **Auto-close** - Closes stale issues after 7 additional days
- 🏷️ **Exemptions** - Skips issues with priority, help wanted, or good first issue labels

## 🔧 Development Workflow

### Making Changes
1. Create feature branch from `main`
2. Make your changes
3. Push branch and create PR
4. **CI workflow** runs automatically
5. **PR Title** and **Labeler** workflows validate and label
6. After review and approval, merge to `main`

### Creating Releases
1. Update version in `pubspec.yaml`
2. Commit and push to `main`
3. Run **Release** workflow with version number
4. Workflow handles validation, testing, building, tagging, and publishing automatically
5. GitHub release created with built APK and AAB files

## 🛠️ Workflow Maintenance

### Adding New Workflows
1. Create `.yml` file in this directory
2. Follow GitHub Actions syntax
3. Test with sample triggers
4. Update this README

### Modifying Existing Workflows
1. Edit the respective `.yml` file
2. Test changes in a feature branch first
3. Update documentation if behavior changes

### Debugging Workflows
1. Check workflow run logs in GitHub Actions tab
2. Use `act` for local testing (optional)
3. Validate YAML syntax before committing

## 📚 Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Flutter CI/CD Guide](https://docs.flutter.dev/deployment/cd)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [Semantic Versioning](https://semver.org/)

## 🔍 Troubleshooting

### Common Issues

**CI fails on format check:**
```bash
# Fix locally
dart format .
git add . && git commit -m "fix: format code"
```

**Version mismatch in Release:**
- Ensure `pubspec.yaml` version matches workflow input
- Version should be without `v` prefix (e.g., `1.2.0` not `v1.2.0`)
- Use semantic versioning format (major.minor.patch)

**PR title validation fails:**
- Use conventional commit format: `type: description`
- Ensure type is from allowed list above

**Quality gates fail in Release:**
- All tests must pass before release
- Code must be properly formatted (`dart format .`)
- No analysis issues allowed (`dart analyze`)

**Build fails in Release:**
- Check Flutter dependencies are up to date
- Ensure all tests pass locally first
- Verify Android build configuration

---

*This documentation is maintained alongside the workflows. Please update when making changes to ensure accuracy.*