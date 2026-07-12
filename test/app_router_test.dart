import 'package:flutter_test/flutter_test.dart';
import 'package:tangankanan/core/routes/app_router.dart';

void main() {
  test('app router can be initialized before PocketBase is ready', () {
    expect(appRouter, isNotNull);
  });
}
