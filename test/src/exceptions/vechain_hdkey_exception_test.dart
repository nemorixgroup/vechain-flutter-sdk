import 'package:flutter_test/flutter_test.dart';
import 'package:vechain_flutter_sdk/vechain_flutter_sdk.dart';

void main() {
  group('VeChainHDKeyException', () {
    test('exposes its message', () {
      const exception = VeChainHDKeyException('bad path');

      expect(exception.message, 'bad path');
    });

    test('toString includes the type name and message', () {
      const exception = VeChainHDKeyException('bad path');

      expect(exception.toString(), 'VeChainHDKeyException: bad path');
    });

    test('is an Exception', () {
      const exception = VeChainHDKeyException('bad path');

      expect(exception, isA<Exception>());
    });
  });
}
