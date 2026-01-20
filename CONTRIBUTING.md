# Contributing Guide

## Commit Pattern (Required)

We follow **Conventional Commits**:

### Structure
type(scope): short description

Examples:
- feat(auth): add password recovery flow
- fix(home): prevent freeze after app resumes
- refactor(agenda): simplify slot generation logic

### Allowed types
- feat       → new feature
- fix        → bug fix
- refactor   → code change without behavior change
- perf       → performance improvement
- style      → formatting only (no logic change)
- test       → tests only
- chore      → tooling, docs, configs

## Versioning

We follow **Semantic Versioning**:

- PATCH → bug fix (1.0.1)
- MINOR → new feature (1.1.0)
- MAJOR → breaking change (2.0.0)

## Rules

- One commit = one responsibility
- No generic messages (update, ajustes, final)
- Every production change must update CHANGELOG.md
- Commits must be in English
