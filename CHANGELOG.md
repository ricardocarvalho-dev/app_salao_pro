# Changelog
Todas as mudanças relevantes deste projeto serão documentadas aqui.

O formato segue:
- Conventional Commits
- Semantic Versioning (MAJOR.MINOR.PATCH)

## [1.0.2] - 2026-01-21
### Added
- Client creation modal integrated into scheduling flow

### Fixed
- Stabilized dropdown behavior after client creation
- Correct provider initialization order to prevent state desync
- Ensured automatic selection of newly created client

### Refactored
- Simplified service duration calculation logic

### Chore
- Updated image dependency to version 4.7.2
- Removed redundant comments from splash screen

## [1.0.1] - 2026-01-20
### Fixed
- Prevent app freeze after background by validating lifecycle and Supabase state

---

## [1.0.0] - 2026-01-18
### Added
- Initial production release
- Supabase backend-first scheduling engine
- D+30 rule with preview-aware availability
