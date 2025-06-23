// ignore_for_file: avoid_print

import 'dart:io';

import 'package:remote_config_gen/remote_config_gen.dart';

Future<void> main(List<String> args) async {
  try {
    final generator = RemoteConfigGenerator();
    await generator.generate();
    print('Remote config files generated successfully!');
  } on RemoteConfigException catch (e) {
    print('Error: ${e.message}');
    exit(1);
  } catch (e) {
    print('Unexpected error: $e');
    exit(1);
  }
}
