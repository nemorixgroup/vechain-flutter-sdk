# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Versioning by phase: each phase is built in small `-dev` sub-versions
and closes with a consolidation release. Phase 1 runs from `0.0.1-dev`
and closes at `0.1.0-dev`; Phase 2 starts at `0.1.1-dev` and closes at
`0.2.0-dev`, and so on.

## 0.0.4-dev

Phase 1 in progress: secp256k1 key pairs, address derivation, and the
EIP-55 address checksum.

### Added

- `VeChainKeyPair.generate`, using `Random.secure()` and discarding any
  value outside the valid range [1, n - 1]
- `VeChainKeyPair.fromPrivateKey`, validating the key length and range
- `VeChainKeyPair` getters for the private key, the 65-byte uncompressed
  public key, the 33-byte compressed public key, and the address
- `VeChainAddress.fromPublicKey` (compressed or uncompressed key),
  `VeChainAddress.parse`, and `VeChainAddress.fromBytes`
- `VeChainAddress.toString` with the EIP-55 mixed-case checksum, and
  value equality by bytes
- `VeChainCryptoException` for invalid keys and curve points, and
  `VeChainAddressException` for invalid addresses
- 67 unit tests, including the official key and address vectors from
  the VeChain SDK for JavaScript and the EIP-55 specification vectors
- Example: `example/phase1/keypair_example.dart`

### Design Decisions

- `VeChainAddress.parse` enforces EIP-55: a mixed-case address must
  match its checksum; the official SDK accepts any mixed case without
  checking it
- Short addresses are rejected instead of being padded with zeros, as
  the official `Address.of` does, because padding produces a different
  valid-looking address
- Public keys are decoded and validated explicitly: only `0x02`/`0x03`
  (33 bytes) or `0x04` (65 bytes), with the curve equation checked and
  compressed points decompressed by the SDK itself, because
  pointycastle's `decodePoint` skips the on-curve check for
  uncompressed points
- Key pair getters return copies and `toString` shows only the address;
  private key bytes cannot be reliably wiped from memory in Dart, so the
  SDK limits exposure instead of promising to erase them
- secp256k1 operations live in an internal `VeChainSecp256k1` class
  shared by keys and addresses; it is not exported

### Status

Phase 1 in progress: key pairs, address derivation and the EIP-55
checksum complete and verified against the official VeChain vectors.  
Not ready for production use.  
Next: Signatures and public key recovery (`0.0.5-dev`).

## 0.0.3-dev

Phase 1 in progress: the two hash functions VeChainThor uses, and a
strict hex codec.

### Added

- `VeChainHash.blake2b256` and `VeChainHash.keccak256`, each returning
  32 bytes
- `VeChainHash.blake2b256Concat` and `VeChainHash.keccak256Concat`,
  which hash several parts as if they were concatenated, mirroring the
  node's multi-input hash functions
- `VeChainHex.encode` (always `0x` plus lowercase digits) and
  `VeChainHex.decode` (optional `0x` prefix, any case)
- `VeChainCodecException`, thrown for invalid hex strings
- 33 unit tests, including the official BLAKE2b-256 and Keccak-256
  vectors from the VeChain SDK for JavaScript
- Example: `example/phase1/hash_example.dart`

### Design Decisions

- Keccak-256 is the legacy Keccak used by Ethereum and by the
  VeChainThor node (`NewLegacyKeccak256`), not SHA3-256; a dedicated
  test guards against mixing them up
- BLAKE2b is configured with a 32-byte digest explicitly, because the
  pointycastle default is 64 bytes
- `VeChainHex.decode` rejects an odd number of digits instead of
  padding with a leading zero as the official `Hex` type does: this
  codec handles bytes (hashes, addresses, signatures), where a missing
  digit is a copy error, not an equivalent value

### Status

Phase 1 in progress: hashing (BLAKE2b-256, Keccak-256) and the hex
codec complete and verified against the official VeChain vectors.  
Not ready for production use.  
Next: Keypair, address and checksum (`0.0.4-dev`).

## 0.0.2-dev

Phase 1 in progress: network configuration, the identity every
transaction depends on.

### Added

- `VeChainNetwork`: an immutable network definition with `name`,
  `genesisId`, `nodeUrl`, a derived `chainTag`, and a `nodeUri` getter
- Official networks as `const` values, usable as default parameters:
  `VeChainNetwork.mainnet` (chain tag `0x4a`),
  `VeChainNetwork.testnet` (`0x27`) and `VeChainNetwork.solo` (`0xf6`)
- `VeChainNetwork.custom` for private or local nodes, with validation:
  non-empty name, a genesis ID of `0x` plus 64 hex characters, and an
  absolute `http`/`https` node URL with a host
- Input normalization in `VeChainNetwork.custom`: surrounding
  whitespace is trimmed, the genesis ID is lowercased, and trailing
  slashes are removed from the node URL
- Value equality (`==` and `hashCode`) and a readable `toString` that
  shows the chain tag in hex
- `VeChainNetworkException`, thrown for any invalid network definition
- 27 unit tests covering the official constants, custom networks,
  normalization, equality, and every validation error
- Example: `example/phase1/network_example.dart`

### Design Decisions

- The chain tag is derived from the last byte of the genesis ID
  instead of being stored, so a network with an inconsistent chain tag
  cannot be built
- `nodeUrl` is a `String` rather than a `Uri`, because `Uri` cannot be
  `const`; official networks need to be `const` to work as default
  parameter values
- The solo node uses `http://127.0.0.1:8669` instead of `localhost`,
  following the official SDK, which does so to avoid IPv6 resolution
  issues
- The EVM chain ID (`0x186a9` on mainnet, `0x186aa` on testnet) is
  intentionally left out: native VeChain transactions use the chain
  tag, and the EVM chain ID will be added with the contracts phase

## 0.0.1-dev

### Added

- Project scaffolding: package structure, MIT license, lint rules
  (`very_good_analysis`), CI workflow, and `pre_commit` scripts for
  macOS/Linux (`.sh`) and Windows (`.ps1`)
- Test layout: unit tests in `test/src/` mirroring `lib/src/`, and
  integration tests against the VeChain testnet in `test/integration/`
  