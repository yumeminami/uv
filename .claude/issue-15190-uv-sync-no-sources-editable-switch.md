# Issue #15190: uv sync does not switch from editable to plain install when run with --no-sources

**URL:** https://github.com/astral-sh/uv/issues/15190
**Status:** opened
**File:** issue-15190-uv-sync-no-sources-editable-switch.md
**Created:** 2025-08-12T17:00:00Z
**Last Updated:** 2025-08-12T17:00:00Z

## 🎯 Issue Analysis (Updated: 2025-08-12T17:00:00Z)

### Problem Description
The `--no-sources` flag in `uv sync` does not properly switch from editable installations back to package installations when run after a regular `uv sync`. This creates inconsistent behavior where the same command produces different results depending on the previous state.

### Expected Behavior
- `uv sync --no-sources` should always produce the same environment state, regardless of previous `uv sync` operations
- When `--no-sources` is specified, dependencies with local sources should be installed as packages, not kept as editable installs

### Current Behavior
1. `uv sync --no-sources` initially installs `poethepoet` as package ✅
2. `uv sync` switches to editable install ✅  
3. `uv sync --no-sources` again makes no changes, leaving editable install ❌

### Root Cause Analysis

#### Architecture Overview
The `uv sync` command follows this flow:
1. **CLI parsing**: `--no-sources` flag is parsed in `crates/uv-cli/src/lib.rs` as `no_sources: bool` field
2. **Settings conversion**: The flag is converted to `SourceStrategy::Disabled` via `SourceStrategy::from_args()` in `crates/uv-configuration/src/sources.rs:15-21`
3. **Dependency lowering**: Requirements are processed in `lock_target.rs:324` using the `lower()` method which respects the `SourceStrategy`
4. **Resolution**: The resolver uses lowered requirements to determine what packages to install
5. **Installation**: The installer compares current state with target state and makes changes

#### The Bug Location
The issue likely occurs in the **state comparison logic** during the sync process. The system:

✅ **Correctly handles** initial `--no-sources` sync (installs from PyPI)
✅ **Correctly handles** regular sync (switches to editable)  
❌ **Fails to handle** subsequent `--no-sources` sync (doesn't switch back to PyPI)

The bug appears to be in the sync logic where the installer doesn't recognize that an editable installation should be replaced with a package installation when `--no-sources` is specified, even though the resolver correctly determines the target state.

#### Key Components Involved
- **sync.rs**: Main sync command implementation (`crates/uv/src/commands/project/sync.rs:58`)
- **SourceStrategy**: Enum controlling source handling (`crates/uv-configuration/src/sources.rs:5-22`)
- **Lock/Resolution**: Dependency resolution respects source strategy correctly
- **Installation comparison**: The gap is likely in comparing current editable vs target package installation

#### Investigation Findings
1. **Source handling works correctly**: `--no-sources` properly disables sources during resolution
2. **Resolution works correctly**: The resolver determines the right packages to install from PyPI
3. **Issue is in sync state comparison**: The installer doesn't detect editable → package transitions as necessary changes

### Technical Context
- Affects any `tool.uv.sources` configurations with `editable=true`
- The `--no-sources` flag converts to `SourceStrategy::Disabled` properly
- Issue confirmed reproducible by maintainer @zanieb
- Related to sync's installation change detection logic

### Impact
- **Inconsistent behavior**: Same command produces different results based on previous state
- **CI/CD issues**: `--no-sources` builds may unexpectedly retain editable packages
- **User workflow disruption**: Requires manual environment recreation or workarounds
- **Determinism**: Breaks the expectation that `--no-sources` produces consistent environments