import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:flutter_ready/flutter_ready.dart';

Future<void> main(List<String> arguments) async {
  final runner = CommandRunner<void>(
    'flutter_ready',
    "Checks a Flutter app's plugins against seasonal platform deadlines.",
  )..addCommand(CheckCommand());

  try {
    await runner.run(arguments);
  } on UsageException catch (error) {
    stderr.writeln(error);
    exitCode = 64;
  }
}
