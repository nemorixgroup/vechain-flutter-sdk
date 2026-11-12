import 'package:flutter_test/flutter_test.dart';
import 'package:vechain_flutter_sdk/vechain_flutter_sdk.dart';

void main() {
  group('VeChainCodecException', () {
    test('exposes its message', () {
      const exception = VeChainCodecException('bad hex');

      expect(exception.message, 'bad hex');
    });

    test('toString includes the type name and message', () {
      const exception = VeChainCodecException('bad hex');

      expect(exception.toString(), 'VeChainCodecException: bad hex');
    });

    test('is an Exception', () {
      const exception = VeChainCodecException('bad hex');

      expect(exception, isA<Exception>());
    });
  });
}
