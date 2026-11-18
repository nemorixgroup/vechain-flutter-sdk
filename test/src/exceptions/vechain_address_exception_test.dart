import 'package:flutter_test/flutter_test.dart';
import 'package:vechain_flutter_sdk/vechain_flutter_sdk.dart';

void main() {
  group('VeChainAddressException', () {
    test('exposes its message', () {
      const exception = VeChainAddressException('bad address');

      expect(exception.message, 'bad address');
    });

    test('toString includes the type name and message', () {
      const exception = VeChainAddressException('bad address');

      expect(exception.toString(), 'VeChainAddressException: bad address');
    });

    test('is an Exception', () {
      const exception = VeChainAddressException('bad address');

      expect(exception, isA<Exception>());
    });
  });
}
