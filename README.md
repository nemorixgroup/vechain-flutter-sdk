[![License: MIT](https://img.shields.io/badge/License-MIT-teal.svg)](https://opensource.org/licenses/MIT)
[![Dart](https://img.shields.io/badge/Dart-3.x-teal.svg)](https://dart.dev)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue.svg)](https://flutter.dev)
[![CI](https://github.com/nemorixgroup/vechain-flutter-sdk/actions/workflows/ci.yml/badge.svg)](https://github.com/nemorixgroup/vechain-flutter-sdk/actions)
[![Status](https://img.shields.io/badge/Status-Phase%201%20In%20Progress-red.svg)](https://github.com/nemorixgroup/vechain-flutter-sdk/blob/main)

**English** | [Español](README.es.md)

# vechain_flutter_sdk

A native Flutter/Dart SDK for the VeChainThor blockchain.
Pure Dart · No platform channels · MIT · pub.dev

> **Status: Early Development** - API is not stable.
> Phase 1 (Foundations) in progress. See
> [CHANGELOG.md](CHANGELOG.md) for details.

Built to be the **foundation for mobile X-to-Earn apps on VeChain**:
wallets, multi-clause transactions, dynamic fees (Galactica), native
fee delegation (VIP-191), smart contracts, and VeBetterDAO integration,
all in one native Dart package.

## Roadmap (v1.0.0)

| Phase | Focus | Versions | Status |
|-------|-------|----------|--------|
| 1 | Foundations (networks, keys, mnemonics, HD wallet, keystore) | `0.1.x` | 🔄 In progress |
| 2 | Thor REST client (accounts, blocks, receipts, fees) | `0.2.x` | ⏳ Planned |
| 3 | Transactions (clauses, intrinsic gas, legacy and dynamic fee) | `0.3.x` | ⏳ Planned |
| 4 | Fee delegation (VIP-191, local and remote gas payer) | `0.4.x` | ⏳ Planned |
| 5 | Contracts and tokens (ABI, ERC-20, events) | `0.5.x` | ⏳ Planned |
| 6 | VeBetter integration (B3TR, VOT3, X2Earn rewards) | `0.6.x` | ⏳ Planned |
| 7 | Certificates (VIP-192) and demo app | `0.7.x` | ⏳ Planned |
| - | Stable release | `1.0.0` | ⏳ Planned |


## Documentation & Knowledge Base

This SDK is built on top of the [VeChain Knowledge Base](https://github.com/nemorixgroup/VeChain-Knowledge-Base),
a beginner-friendly guide to VeChainThor covering its consensus,
dual-token model, transaction model, fee delegation, and the VeBetterDAO
ecosystem. Recommended reading before diving into the SDK internals.

Every implementation decision behind this SDK (library choices,
encoding standards, verification against official specs) is documented
in [docs-sdk/](https://github.com/nemorixgroup/VeChain-Knowledge-Base/tree/main/docs-sdk).

## Installation

```yaml
# pubspec.yaml
dependencies:
  vechain_flutter_sdk: ^0.0.1-dev
```

```bash
flutter pub get
```

## Quick Start

Examples will be added with each release, starting with `0.0.1-dev`.

## Networks

| Network | Chain Tag | Explorer |
|---------|-----------|----------|
| Mainnet | `0x4a` | [explore.vechain.org](https://explore.vechain.org) |
| Testnet | `0x27` | [explore-testnet.vechain.org](https://explore-testnet.vechain.org) |
| Solo | `0xf6` | Local node |

## Contributing

The SDK is not ready for external contributions yet.
Follow this repository for updates; contributions will
be welcome starting with v1.0.0.

See [CONTRIBUTING.md](CONTRIBUTING.md) for future guidelines.

## License

Licensed under the [MIT License](LICENSE).

## For LATAM developers

This SDK is being developed with native support for the region in mind:

- Bilingual documentation (English / Spanish) from the very first module.
- Part of Nemorix Group's SDK ecosystem for financial infrastructure
  in LATAM (Hedera, Avalanche, XRPL, Solana, Flare, Stronghold, VeChain).
- Developed by [Nemorix Group](https://nemorixpay.com), Ohio, USA.

Follow us for updates: **sdks@nemorixpay.com**

## Support This Project

If this SDK is useful to you or your team, consider supporting its
development. Every contribution helps cover infrastructure,
documentation, and the time invested in building and maintaining this
open source tool for the VeChain and Flutter community. Thank you!

[![Buy Me a Coffee](https://img.shields.io/badge/Buy%20Me%20A%20Coffee-Support-FFDD00?logo=buy-me-a-coffee&logoColor=black)](https://buymeacoffee.com/nemorixgroupllc)
[![Sponsor](https://img.shields.io/badge/Sponsor-GitHub-EA4AAA?logo=github-sponsors&logoColor=white)](https://github.com/sponsors/nemorixgroup)
[![Ko-fi](https://img.shields.io/badge/Ko--fi-Support-FF5E5B?logo=ko-fi&logoColor=white)](https://ko-fi.com/nemorixgroupllc)

---

Built by [Nemorix Group](https://nemorixpay.com) · MIT
