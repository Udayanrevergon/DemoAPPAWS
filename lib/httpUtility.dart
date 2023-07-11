import 'dart:convert';

import 'package:http/http.dart' as http;

class HttpUtility {
  Future<String> httpPost(
      {required String server,
      required String path,
      required Map<String, dynamic> queryParams,
      required Object payload,
      required Map<String, String> headers}) async {
    var url = Uri.https(server, path);
    return http
        .post(url,
            body: payload,
            encoding: Encoding.getByName('base64'),
            headers: headers)
        .then((value) {
      if (value.statusCode != 200) {
        print("Hello+$payload");

        print("Value from POST,statusCode,body: ");
        print(value.statusCode);
        print(value.body);
        throw Exception(
            "Recerived Bad Request from the endpoint for POST request:${value.statusCode}");
      }
      return value.body;
    }, onError: (value) {
      print("http exception");
      print(value);
      return "";
    });
  }
}
