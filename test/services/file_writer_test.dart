import 'dart:io';
import 'package:test/test.dart';
import 'package:remote_config_gen/src/services/file_writer.dart';
import 'package:remote_config_gen/src/exceptions/remote_config_exception.dart';

void main() {
  group('FileWriter', () {
    late Directory tempDir;
    late FileWriter fileWriter;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('file_writer_test_');
      fileWriter = const FileWriter();
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    group('writeGeneratedCode', () {
      test('writes code to file successfully', () async {
        const generatedCode = '''
class RemoteConfigParams {
  static const test = 'value';
}
''';

        await fileWriter.writeGeneratedCode(
          outputPath: tempDir.path,
          generatedCode: generatedCode,
        );

        final outputFile = File(
          '${tempDir.path}/remote_config_params.gen.dart',
        );
        expect(outputFile.existsSync(), isTrue);

        final content = await outputFile.readAsString();
        expect(content, equals(generatedCode));
      });

      test('creates output directory if it does not exist', () async {
        final nonExistentDir = '${tempDir.path}/nested/directory';
        expect(Directory(nonExistentDir).existsSync(), isFalse);

        await fileWriter.writeGeneratedCode(
          outputPath: nonExistentDir,
          generatedCode: 'test content',
        );

        expect(Directory(nonExistentDir).existsSync(), isTrue);
        final outputFile = File(
          '$nonExistentDir/remote_config_params.gen.dart',
        );
        expect(outputFile.existsSync(), isTrue);
      });

      test('uses custom filename when provided', () async {
        const customFileName = 'custom_config.dart';

        await fileWriter.writeGeneratedCode(
          outputPath: tempDir.path,
          generatedCode: 'test content',
          fileName: customFileName,
        );

        final outputFile = File('${tempDir.path}/$customFileName');
        expect(outputFile.existsSync(), isTrue);
      });

      test('overwrites existing file', () async {
        final outputFile = File(
          '${tempDir.path}/remote_config_params.gen.dart',
        );
        await outputFile.writeAsString('original content');

        await fileWriter.writeGeneratedCode(
          outputPath: tempDir.path,
          generatedCode: 'new content',
        );

        final content = await outputFile.readAsString();
        expect(content, equals('new content'));
      });

      test('handles large generated code', () async {
        final largeCode =
            'class Test {\n' +
            ('  static const param = "value";\n' * 1000) +
            '}';

        await fileWriter.writeGeneratedCode(
          outputPath: tempDir.path,
          generatedCode: largeCode,
        );

        final outputFile = File(
          '${tempDir.path}/remote_config_params.gen.dart',
        );
        final content = await outputFile.readAsString();
        expect(content, equals(largeCode));
        expect(content.length, greaterThan(10000));
      });

      test('handles special characters in generated code', () async {
        const specialCode = '''
class RemoteConfigParams {
  static const emoji = "🚀 Test";
  static const unicode = "Test with ünicode";
  static const quotes = "Contains 'single' and \"double\" quotes";
  static const newlines = "Line 1\\nLine 2\\nLine 3";
}
''';

        await fileWriter.writeGeneratedCode(
          outputPath: tempDir.path,
          generatedCode: specialCode,
        );

        final outputFile = File(
          '${tempDir.path}/remote_config_params.gen.dart',
        );
        final content = await outputFile.readAsString();
        expect(content, equals(specialCode));
      });

      test(
        'throws CodeGenerationException when output path is invalid',
        () async {
          final invalidPath =
              '/invalid/path/that/does/not/exist/and/cannot/be/created';

          await expectLater(
            () => fileWriter.writeGeneratedCode(
              outputPath: invalidPath,
              generatedCode: 'test',
            ),
            throwsA(
              isA<CodeGenerationException>().having(
                (e) => e.message,
                'message',
                contains('Failed to write generated code'),
              ),
            ),
          );
        },
      );

      test(
        'throws CodeGenerationException when file cannot be written',
        () async {
          // Create a directory with the same name as the target file
          final conflictingDir = Directory(
            '${tempDir.path}/remote_config_params.gen.dart',
          );
          await conflictingDir.create();

          await expectLater(
            () => fileWriter.writeGeneratedCode(
              outputPath: tempDir.path,
              generatedCode: 'test',
            ),
            throwsA(
              isA<CodeGenerationException>().having(
                (e) => e.message,
                'message',
                contains('Failed to write generated code'),
              ),
            ),
          );
        },
      );

      test('handles empty generated code', () async {
        await fileWriter.writeGeneratedCode(
          outputPath: tempDir.path,
          generatedCode: '',
        );

        final outputFile = File(
          '${tempDir.path}/remote_config_params.gen.dart',
        );
        expect(outputFile.existsSync(), isTrue);
        final content = await outputFile.readAsString();
        expect(content, isEmpty);
      });

      test('handles paths with spaces and special characters', () async {
        final specialDir = Directory(
          '${tempDir.path}/path with spaces & symbols',
        );
        await specialDir.create();

        await fileWriter.writeGeneratedCode(
          outputPath: specialDir.path,
          generatedCode: 'test content',
        );

        final outputFile = File(
          '${specialDir.path}/remote_config_params.gen.dart',
        );
        expect(outputFile.existsSync(), isTrue);
      });
    });
  });
}
