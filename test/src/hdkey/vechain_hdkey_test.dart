import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:vechain_flutter_sdk/vechain_flutter_sdk.dart';

import '../../support/bip32_vectors.dart';

// ---- Official VeChain vectors (vechain-sdk-js HDKey and Mnemonic tests) ----

const _phrase = 'ignore empty bird silly journey junior '
    'ripple have guard waste between tenant';

/// Addresses of accounts 0 to 4 under m/44'/818'/0'/0.
const _addresses = [
  '0x339Fb3C438606519E2C75bbf531fb43a0F449A70',
  '0x5677099D06Bc72f9da1113aFA5e022feEc424c8E',
  '0x86231b5CDCBfE751B9DdCD4Bd981fC0A48afe921',
  '0xd6f184944335f26Ea59dbB603E38e2d434220fcD',
  '0x2AC1a0AeCd5C80Fb5524348130ab7cf92670470A',
];

/// Private key at m/44'/818'/0'/0/0.
const _account0PrivateKey =
    '0x27196338e7d0b5e7bf1be1c0327c53a244a18ef0b102976980e341500f492425';

/// Private key at the custom path m/0/1.
const _customPathPrivateKey =
    '0x731311cb9643cf4cf7a3a051fe02ae56cf6887708d1f2d3b07e1b4bebeb742a8';

/// Private key at the deep custom path m/0/1/4/2/4/3.
const _deepPathPrivateKey =
    '0x4d61a740e8e9964284c96e92e5e95e05eb732d61a5c3fb1557ca99398f041ba0';

/// Decodes a hex constant into bytes.
Uint8List _hex(String hex) => VeChainHex.decode(hex);

/// The official VeChain test mnemonic.
VeChainMnemonic _mnemonic() => VeChainMnemonic.parse(_phrase);

/// The master node of the official VeChain test mnemonic.
VeChainHDKey _master() => VeChainHDKey.fromSeed(_mnemonic().toSeed());

/// Expected child number of the last component of [path].
int _lastIndex(String path) {
  final last = path.split('/').last;
  if (last == 'm') return 0;
  final hardened = last.endsWith("'");
  final value = int.parse(hardened ? last.substring(0, last.length - 1) : last);
  return hardened ? value + VeChainHDKey.hardenedOffset : value;
}

/// The official BIP-32 node at [path] of test [vector].
({
  int vector,
  String seed,
  String path,
  String chainCode,
  String privateKey,
  String publicKey,
}) _node(int vector, String path) => bip32TestVectors
    .firstWhere((node) => node.vector == vector && node.path == path);

/// Matches a [VeChainHDKeyException] whose message contains [text].
Matcher _throwsHDKeyException(String text) => throwsA(
      isA<VeChainHDKeyException>().having(
        (e) => e.message,
        'message',
        contains(text),
      ),
    );

void main() {
  group('VeChainHDKey official BIP-32 vectors', () {
    test('every node matches the official private key and chain code', () {
      for (final node in bip32TestVectors) {
        final key = VeChainHDKey.fromSeed(_hex(node.seed)).derive(node.path);

        expect(VeChainHex.encode(key.privateKey!), node.privateKey);
        expect(VeChainHex.encode(key.chainCode), node.chainCode);
      }
    });

    test('every node matches the official public key', () {
      for (final node in bip32TestVectors) {
        final key = VeChainHDKey.fromSeed(_hex(node.seed)).derive(node.path);

        expect(VeChainHex.encode(key.publicKey), node.publicKey);
      }
    });

    test('depth and index follow the path', () {
      for (final node in bip32TestVectors) {
        final key = VeChainHDKey.fromSeed(_hex(node.seed)).derive(node.path);

        expect(key.depth, node.path.split('/').length - 1);
        expect(key.index, _lastIndex(node.path));
      }
    });
  });

  group('VeChainHDKey and the official VeChain mnemonic', () {
    test('fromMnemonic derives the official account addresses', () {
      final root = VeChainHDKey.fromMnemonic(_mnemonic());

      for (var i = 0; i < _addresses.length; i++) {
        expect(root.deriveChild(i).address.toString(), _addresses[i]);
      }
    });

    test('account 0 has the official private key', () {
      final account0 = VeChainHDKey.fromMnemonic(_mnemonic()).deriveChild(0);

      expect(VeChainHex.encode(account0.privateKey!), _account0PrivateKey);
    });

    test('custom paths give the official private keys', () {
      final custom = VeChainHDKey.fromMnemonic(_mnemonic(), path: 'm/0/1');
      final deep =
          VeChainHDKey.fromMnemonic(_mnemonic(), path: 'm/0/1/4/2/4/3');

      expect(VeChainHex.encode(custom.privateKey!), _customPathPrivateKey);
      expect(VeChainHex.encode(deep.privateKey!), _deepPathPrivateKey);
    });

    test('deriveChild(i) equals the full path to account i', () {
      final root = VeChainHDKey.fromMnemonic(_mnemonic());
      final master = _master();

      for (var i = 0; i < 5; i++) {
        final fromChild = root.deriveChild(i);
        final fromPath = master.derive('${VeChainHDKey.vetDerivationPath}/$i');
        expect(fromChild.privateKey, fromPath.privateKey);
      }
    });

    test('a passphrase gives different accounts', () {
      final withPassphrase =
          VeChainHDKey.fromMnemonic(_mnemonic(), passphrase: 'TREZOR');

      expect(
        withPassphrase.deriveChild(0).address.toString(),
        isNot(_addresses[0]),
      );
    });
  });

  group('VeChainHDKey.fromPrivateKey', () {
    test('a restored node derives the official addresses', () {
      final root = VeChainHDKey.fromMnemonic(_mnemonic());
      final restored =
          VeChainHDKey.fromPrivateKey(root.privateKey!, root.chainCode);

      for (var i = 0; i < _addresses.length; i++) {
        expect(restored.deriveChild(i).address.toString(), _addresses[i]);
      }
    });

    test('throws on a chain code that is not 32 bytes (official)', () {
      expect(
        () => VeChainHDKey.fromPrivateKey(
          _hex(_account0PrivateKey),
          Uint8List(31),
        ),
        _throwsHDKeyException('Invalid chain code: expected 32 bytes, got 31'),
      );
    });

    test('throws on an invalid private key (official)', () {
      expect(
        () => VeChainHDKey.fromPrivateKey(Uint8List(31), Uint8List(32)),
        throwsA(isA<VeChainCryptoException>()),
      );
      expect(
        () => VeChainHDKey.fromPrivateKey(Uint8List(32), Uint8List(32)),
        throwsA(isA<VeChainCryptoException>()),
      );
    });

    test('copies its inputs, so later changes do not affect it', () {
      final key = _hex(_account0PrivateKey);
      final chainCode = Uint8List(32);
      final node = VeChainHDKey.fromPrivateKey(key, chainCode);
      key[0] = 0x00;
      chainCode[0] = 0xff;

      expect(VeChainHex.encode(node.privateKey!), _account0PrivateKey);
      expect(node.chainCode[0], 0);
    });
  });

  group('VeChainHDKey.fromPublicKey (watch-only)', () {
    test('derives the official addresses without a private key', () {
      final root = VeChainHDKey.fromMnemonic(_mnemonic());
      final watcher =
          VeChainHDKey.fromPublicKey(root.publicKey, root.chainCode);

      expect(watcher.isWatchOnly, isTrue);
      for (var i = 0; i < _addresses.length; i++) {
        final child = watcher.deriveChild(i);
        expect(child.privateKey, isNull);
        expect(child.address.toString(), _addresses[i]);
      }
    });

    test('public derivation matches the official BIP-32 public keys', () {
      // Vector 1: m/0'/1/2' -> /2 -> /1000000000, all normal steps.
      final parent = _node(1, "m/0'/1/2'");
      final watcher = VeChainHDKey.fromPublicKey(
        _hex(parent.publicKey),
        _hex(parent.chainCode),
      );
      final child = watcher.deriveChild(2);
      final grandchild = child.deriveChild(1000000000);

      expect(
        VeChainHex.encode(child.publicKey),
        _node(1, "m/0'/1/2'/2").publicKey,
      );
      expect(
        VeChainHex.encode(grandchild.publicKey),
        _node(1, "m/0'/1/2'/2/1000000000").publicKey,
      );

      // Vector 2: m -> /0, a normal step from the master.
      final master = _node(2, 'm');
      final masterWatcher = VeChainHDKey.fromPublicKey(
        _hex(master.publicKey),
        _hex(master.chainCode),
      );
      expect(
        VeChainHex.encode(masterWatcher.deriveChild(0).publicKey),
        _node(2, 'm/0').publicKey,
      );
    });

    test('throws on a hardened child', () {
      final root = VeChainHDKey.fromMnemonic(_mnemonic());
      final watcher =
          VeChainHDKey.fromPublicKey(root.publicKey, root.chainCode);

      expect(
        () => watcher.deriveChild(0, hardened: true),
        _throwsHDKeyException('Cannot derive a hardened child'),
      );
      expect(
        () => watcher.derive("m/0'"),
        _throwsHDKeyException('Cannot derive a hardened child'),
      );
    });

    test('keyPair throws on a watch-only node', () {
      final root = VeChainHDKey.fromMnemonic(_mnemonic());
      final watcher =
          VeChainHDKey.fromPublicKey(root.publicKey, root.chainCode);

      expect(() => watcher.keyPair, _throwsHDKeyException('watch-only'));
    });

    test('throws on an invalid chain code or public key (official)', () {
      expect(
        () => VeChainHDKey.fromPublicKey(Uint8List(32), Uint8List(31)),
        _throwsHDKeyException('Invalid chain code'),
      );
      expect(
        () => VeChainHDKey.fromPublicKey(Uint8List(31), Uint8List(32)),
        throwsA(isA<VeChainCryptoException>()),
      );
    });
  });

  group('VeChainHDKey.keyPair', () {
    test('account 0 signs as the official address', () {
      final keyPair =
          VeChainHDKey.fromMnemonic(_mnemonic()).deriveChild(0).keyPair;
      final hash = VeChainHash.keccak256(
        Uint8List.fromList(utf8.encode('VeChainThor')),
      );

      expect(keyPair.address.toString(), _addresses[0]);
      expect(keyPair.sign(hash).recoverAddress(hash), keyPair.address);
    });
  });

  group('VeChainHDKey paths and indexes', () {
    test('"m" returns the same node', () {
      final master = _master();

      expect(identical(master.derive('m'), master), isTrue);
    });

    test('rejects the official invalid paths and other malformed ones', () {
      final master = _master();
      const invalid = [
        '0/1/4/2/4/h',
        'm/0/1/4/2/4/h',
        'a',
        'm/0/b',
        'incorrect',
        'inco/rre/01/ct',
        '1/0/1',
        'm/',
        "m/0''",
        'm/-1',
      ];

      for (final path in invalid) {
        expect(
          () => master.derive(path),
          _throwsHDKeyException('Invalid derivation path'),
          reason: path,
        );
      }
    });

    test('accepts every valid BIP-32 path shape', () {
      final master = _master();
      const valid = [
        VeChainHDKey.vetDerivationPath,
        'm/0/1/2/3/4',
        "m/0'/1'/2'/3/4",
        "m/44'/60'/0'/0/0",
        "m/44'/60'/0'/0",
        'm/0/1/2/3',
        // Rejected by the official isDerivationPathValid, but derivable.
        "m/0'/1'/2/3'/4'",
      ];

      for (final path in valid) {
        expect(master.derive(path).depth, path.split('/').length - 1);
      }
    });

    test('rejects an index of 2^31 or more in a path', () {
      expect(
        () => _master().derive('m/2147483648'),
        _throwsHDKeyException('index 2147483648 is out of range'),
      );
    });

    test('deriveChild rejects indexes outside [0, 2^31 - 1]', () {
      final master = _master();

      expect(
        () => master.deriveChild(-1),
        _throwsHDKeyException('Invalid child index -1'),
      );
      expect(
        () => master.deriveChild(VeChainHDKey.hardenedOffset),
        _throwsHDKeyException('Invalid child index'),
      );
    });

    test('a hardened deriveChild equals the hardened path', () {
      final master = _master();

      expect(
        master.deriveChild(0, hardened: true).privateKey,
        master.derive("m/0'").privateKey,
      );
    });
  });

  group('VeChainHDKey.fromSeed', () {
    test('accepts seeds of 16 to 64 bytes and rejects others', () {
      expect(VeChainHDKey.fromSeed(Uint8List(16)).depth, 0);
      expect(VeChainHDKey.fromSeed(Uint8List(64)).depth, 0);
      expect(
        () => VeChainHDKey.fromSeed(Uint8List(15)),
        _throwsHDKeyException('Invalid seed: expected 16 to 64 bytes, got 15'),
      );
      expect(
        () => VeChainHDKey.fromSeed(Uint8List(65)),
        _throwsHDKeyException('got 65'),
      );
    });
  });

  group('VeChainHDKey protects its secrets', () {
    test('toString never shows the private key or the chain code', () {
      final account0 = VeChainHDKey.fromMnemonic(_mnemonic()).deriveChild(0);
      final text = account0.toString().toLowerCase();

      expect(text, contains(_addresses[0].toLowerCase()));
      expect(text, isNot(contains(_account0PrivateKey.substring(2))));
      expect(
        text,
        isNot(contains(VeChainHex.encode(account0.chainCode).substring(2))),
      );
    });

    test('getters return copies', () {
      final account0 = VeChainHDKey.fromMnemonic(_mnemonic()).deriveChild(0);
      account0.privateKey![0] = 0x00;
      account0.chainCode[0] = 0x00;
      account0.publicKey[1] = 0x00;

      expect(VeChainHex.encode(account0.privateKey!), _account0PrivateKey);
      expect(account0.address.toString(), _addresses[0]);
    });
  });
}
