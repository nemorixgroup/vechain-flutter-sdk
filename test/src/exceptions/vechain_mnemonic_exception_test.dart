import 'package:flutter_test/flutter_test.dart';
import 'package:vechain_flutter_sdk/vechain_flutter_sdk.dart';

void main() {
  group('VeChainMnemonicException', () {
    test('exposes its message', () {
      const exception = VeChainMnemonicException('bad mnemonic');

      expect(exception.message, 'bad mnemonic');
    });

    test('toString includes the type name and message', () {
      const exception = VeChainMnemonicException('bad mnemonic');

      expect(exception.toString(), 'VeChainMnemonicException: bad mnemonic');
    });

    test('is an Exception', () {
      const exception = VeChainMnemonicException('bad mnemonic');

      expect(exception, isA<Exception>());
    });
  });
}
