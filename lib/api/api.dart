import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CallApi {
  static const String _baseUrl = 'https://impresora.xeler.io/api/';

  Future<http.Response> postData(
    Map<String, dynamic> data,
    String apiUrl,
  ) async {
    final uri = await _buildUri(apiUrl);
    return http.post(
      uri,
      body: jsonEncode(data),
      headers: _headers,
    );
  }

  Future<http.Response> getData(String apiUrl) async {
    final uri = await _buildUri(apiUrl);
    return http.get(uri, headers: _headers);
  }

  Future<Uri> _buildUri(String apiUrl) async {
    final tokenQuery = await _tokenQuery();
    final separator = apiUrl.contains('?') ? '&' : '?';
    return Uri.parse('$_baseUrl$apiUrl$separator$tokenQuery');
  }

  Map<String, String> get _headers => const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  Future<String> _tokenQuery() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return 'token=${token ?? ''}';
  }
}
