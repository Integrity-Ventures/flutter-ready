import 'package:flutter_ready/flutter_ready.dart';
import 'package:test/test.dart';

void main() {
  test('parses a populated replacements map', () {
    final result = parseReplacements('''
      {
        "some_plugin": [
          {"replacement": "some_plugin_plus", "note": "SwiftPM-ready fork", "source": "hand-checked"}
        ]
      }
    ''');

    expect(result, hasLength(1));
    final suggestions = result['some_plugin']!;
    expect(suggestions, hasLength(1));
    expect(suggestions.single.replacement, 'some_plugin_plus');
    expect(suggestions.single.note, 'SwiftPM-ready fork');
    expect(suggestions.single.source, 'hand-checked');
  });

  test('an empty object parses to an empty map', () {
    expect(parseReplacements('{}'), isEmpty);
  });

  test('entries missing note or source default to empty strings', () {
    final result = parseReplacements('{"some_plugin": [{"replacement": "some_plugin_plus"}]}');

    final suggestion = result['some_plugin']!.single;
    expect(suggestion.replacement, 'some_plugin_plus');
    expect(suggestion.note, '');
    expect(suggestion.source, '');
  });
}
