# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Versioning by phase: phase N uses `0.N.x`. Intermediate releases carry
the `-dev` suffix; the last release of each phase is published without
it, marking the phase as complete.

## Unreleased

### Added

- Project scaffolding: package structure, MIT license, lint rules
  (`very_good_analysis`), CI workflow, and `pre_commit` scripts for
  macOS/Linux (`.sh`) and Windows (`.ps1`)
- Test layout: unit tests in `test/src/` mirroring `lib/src/`, and
  integration tests against the VeChain testnet in `test/integration/`
  