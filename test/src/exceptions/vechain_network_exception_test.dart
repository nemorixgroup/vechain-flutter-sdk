import 'package:flutter_test/flutter_test.dart';
import 'package:vechain_flutter_sdk/vechain_flutter_sdk.dart';

void main() {
  group('VeChainNetworkException', () {
    test('exposes its message', () {
      const exception = VeChainNetworkException('bad genesis');

      expect(exception.message, 'bad genesis');
    });

    test('toString includes the type name and message', () {
      const exception = VeChainNetworkException('bad genesis');

      expect(exception.toString(), 'VeChainNetworkException: bad genesis');
    });

    test('is an Exception', () {
      const exception = VeChainNetworkException('bad genesis');

      expect(exception, isA<Exception>());
    });
  });
}
