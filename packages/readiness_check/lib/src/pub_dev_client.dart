import 'dart:convert';

import 'package:http/http.dart' as http;

/// Thrown when a pub.dev API call does not return HTTP 200.
class PubDevApiException implements Exception {
  PubDevApiException(this.uri, this.statusCode);

  final Uri uri;
  final int statusCode;

  @override
  String toString() => 'PubDevApiException: $statusCode fetching $uri';
}

/// Thin wrapper around the two pub.dev endpoints the readiness checks need.
///
/// See SPEC.md §3.1.1: package-name-completion-data returns names "ordered by
/// overall ranking"; the score endpoint carries the tags used to identify
/// Flutter plugins and (in later checks) SwiftPM support.
class PubDevClient {
  PubDevClient({http.Client? httpClient, Uri? baseUri})
    : _httpClient = httpClient ?? http.Client(),
      _baseUri = baseUri ?? Uri.parse('https://pub.dev');

  final http.Client _httpClient;
  final Uri _baseUri;

  /// All package names known to pub.dev, ordered by overall ranking.
  Future<List<String>> fetchPackageNames() async {
    final uri = _baseUri.resolve('/api/package-name-completion-data');
    final body = await _getJson(uri);
    return (body['packages'] as List).cast<String>();
  }

  /// Score tags for a single package, e.g. `sdk:flutter`, `platform:ios`.
  Future<List<String>> fetchPackageTags(String packageName) async {
    final uri = _baseUri.resolve('/api/packages/$packageName/score');
    final body = await _getJson(uri);
    return (body['tags'] as List? ?? const []).cast<String>();
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    final response = await _httpClient.get(uri);
    if (response.statusCode != 200) {
      throw PubDevApiException(uri, response.statusCode);
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
