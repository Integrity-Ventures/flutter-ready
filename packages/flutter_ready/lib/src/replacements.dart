import 'dart:convert';

/// A hand-kept suggestion for a blocked package (SPEC §3.3, open decision
/// 4: hand-curated, never generated).
class Replacement {
  const Replacement({
    required this.replacement,
    this.note = '',
    this.source = '',
  });

  final String replacement;
  final String note;
  final String source;
}

/// Parses `data/replacements.json`, a map of package name to a list of
/// replacement objects:
///
/// ```json
/// {"package_name": [{"replacement": "...", "note": "...", "source": "..."}]}
/// ```
///
/// Pure, no IO, so an empty or absent file ('{}') parses to an empty map.
Map<String, List<Replacement>> parseReplacements(String contents) {
  final json = jsonDecode(contents) as Map<String, dynamic>;
  return {
    for (final entry in json.entries)
      entry.key: [
        for (final item in entry.value as List)
          Replacement(
            replacement:
                (item as Map<String, dynamic>)['replacement'] as String,
            note: item['note'] as String? ?? '',
            source: item['source'] as String? ?? '',
          ),
      ],
  };
}
