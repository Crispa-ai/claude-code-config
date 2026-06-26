---
name: test
description: A no-op smoke-test skill used to verify the plugin update/version-bump workflow end to end. Use only when explicitly checking whether plugin updates propagate to Claude Code and Cowork after a version bump and marketplace re-sync.
---

# Test Skill

This skill exists solely to verify that plugin updates propagate correctly after a
version bump and a marketplace re-sync. It performs no real work and can be removed
once the update workflow is confirmed.

When invoked, respond with exactly:

> ✅ crispa-config test skill is active (v1.1.0) — plugin update workflow verified.

If you can see and run this skill in Cowork, the new-skill release path
(bump version → merge to `main` → re-sync / reinstall) is working.
