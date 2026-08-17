import 'package:flutter_test/flutter_test.dart';
import 'package:zindagi_plus/core/network/result.dart';

void main() {
  group('Result<T>', () {
    test('Success holds its data value', () {
      const r = Success(42);
      expect(r, isA<Success<int>>());
      expect(r.data, equals(42));
    });

    test('Failure holds its message', () {
      const r = Failure<int>('Something went wrong');
      expect(r, isA<Failure<int>>());
      expect(r.message, equals('Something went wrong'));
    });

    test('pattern match on Success', () {
      const Result<String> r = Success('hello');
      final matched = switch (r) {
        Success(data: final d) => d,
        Failure() => 'fail',
      };
      expect(matched, equals('hello'));
    });

    test('pattern match on Failure', () {
      const Result<String> r = Failure('oops');
      final matched = switch (r) {
        Success() => 'ok',
        Failure(message: final m) => m,
      };
      expect(matched, equals('oops'));
    });

    test('Success<void> works', () {
      const r = Success<void>(null);
      expect(r, isA<Success<void>>());
    });

    test('toString on Success', () {
      const r = Success(10);
      expect(r.toString(), contains('Success'));
      expect(r.toString(), contains('10'));
    });

    test('toString on Failure', () {
      const r = Failure<int>('err');
      expect(r.toString(), contains('Failure'));
      expect(r.toString(), contains('err'));
    });
  });
}
