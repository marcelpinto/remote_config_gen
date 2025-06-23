import 'package:test/test.dart';
import 'package:remote_config_gen/src/utils/string_utils.dart';

void main() {
  group('StringUtils', () {
    group('toCamelCase', () {
      test('converts snake_case to camelCase', () {
        expect(StringUtils.toCamelCase('hello_world'), equals('helloWorld'));
        expect(
          StringUtils.toCamelCase('hello_world_test'),
          equals('helloWorldTest'),
        );
      });

      test('handles already camelCase strings', () {
        expect(StringUtils.toCamelCase('helloWorld'), equals('helloWorld'));
        expect(StringUtils.toCamelCase('hello'), equals('hello'));
      });

      test('handles empty strings and edge cases', () {
        expect(StringUtils.toCamelCase(''), equals(''));
        expect(StringUtils.toCamelCase('_'), equals(''));
        expect(StringUtils.toCamelCase('hello_'), equals('hello'));
        expect(StringUtils.toCamelCase('_hello'), equals('Hello'));
      });
    });

    group('toClassName', () {
      test('converts snake_case to ClassName', () {
        expect(StringUtils.toClassName('hello_world'), equals('HelloWorld'));
        expect(
          StringUtils.toClassName('remote_config_params'),
          equals('RemoteConfigParams'),
        );
      });

      test('handles single words', () {
        expect(StringUtils.toClassName('hello'), equals('Hello'));
        expect(StringUtils.toClassName('test'), equals('Test'));
      });

      test('handles empty strings and edge cases', () {
        expect(StringUtils.toClassName(''), equals(''));
        expect(StringUtils.toClassName('_'), equals(''));
        expect(StringUtils.toClassName('hello_'), equals('Hello'));
      });
    });
  });
}
