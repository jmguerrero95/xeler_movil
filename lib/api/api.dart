import 'package:http/http.dart' as http;
import 'dart:convert' as convert;

import 'package:shared_preferences/shared_preferences.dart';

class CallApi{
  final String _url = 'https://impresora.xeler.io/api/';

    postData(data, apiUrl) async {
        var fullUrl = _url + apiUrl + await _getToken();
        return await http.post(
          fullUrl,
          body: convert.jsonEncode(data),
          headers: _setHeaders()
        );
    }

    getData(apiUrl) async {
      var fullUrl = _url + apiUrl + await _getToken();
      return await http.get(
        fullUrl,
        headers: _setHeaders()
      );
    }



    _setHeaders() => {
          'Content-type' : 'application/json',
          'Accept' : 'application/json'
    };

    _getToken() async {
        SharedPreferences localStorage = await SharedPreferences.getInstance();
        var token = localStorage.getString('token');
        return '?token=$token';
    }
}