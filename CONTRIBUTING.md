# Contributing

Thank you for your interest in `vechain_flutter_sdk`.

> **Status: Early Development.** The SDK is not ready for external
> contributions yet. Follow this repository for updates; contributions
> will be welcome starting with v1.0.0.

## Development workflow (internal)

1. One commit per logical responsibility, using [Conventional Commits](https://www.conventionalcommits.org/).
2. Run `scripts/pre_commit.sh` (macOS/Linux) or `scripts/pre_commit.ps1`
   (Windows) before every commit; it must pass green.
3. Follow the phase-by-phase workflow: implementation, tests, examples,
   then documentation.

## Tests

- Unit tests live in `test/src/`, mirroring the structure of `lib/src/`.
  They run offline.
- Integration tests live in `test/integration/` and end in
  `_integration_test.dart`. They make real network calls against the
  VeChain testnet.

## Code style

- Follows [very_good_analysis](https://pub.dev/packages/very_good_analysis) lint rules.
- Every public element is documented with dartdoc.
- All technical content and implementation decisions must be based on
  official sources only (docs.vechain.org, the vechain GitHub
  organization, official VIPs).
  