import 'package:flutter_architecture_generator/flutter_architecture_generator.dart';
import 'package:test/test.dart';

void main() {
  group('FlutterArchGenRunner', () {
    test('runner has correct executable name', () {
      final runner = FlutterArchGenRunner();
      expect(runner.executableName, 'flutter_arch_gen');
    });

    test('runner has correct description', () {
      final runner = FlutterArchGenRunner();
      expect(runner.description, contains('CLI tool'));
    });

    test('runner has all expected commands', () {
      final runner = FlutterArchGenRunner();
      expect(runner.commands.keys,
          containsAll(['init', 'feature', 'model', 'page']));
    });
  });
}
