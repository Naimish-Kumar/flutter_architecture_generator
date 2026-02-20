import 'dart:io';
import 'package:flutter_architecture_generator/flutter_architecture_generator.dart';

Future<void> main(List<String> args) async {
  final runner = FlutterArchGenRunner();
  final exitCode = await runner.run(args);
  exit(exitCode ?? 0);
}
