import 'package:flutter_test/flutter_test.dart';
import 'package:vechain_flutter_sdk/vechain_flutter_sdk.dart';

void main() {
  group('VeChainCryptoException', () {
    test('exposes its message', () {
      const exception = VeChainCryptoException('bad key');

      expect(exception.message, 'bad key');
    });

    test('toString includes the type name and message', () {
      const exception = VeChainCryptoException('bad key');

      expect(exception.toString(), 'VeChainCryptoException: bad key');
    });

    test('is an Exception', () {
      const exception = VeChainCryptoException('bad key');

      expect(exception, isA<Exception>());
    });
  });
}
