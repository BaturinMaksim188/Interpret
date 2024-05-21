import 'dart:convert';
import 'package:http/http.dart' as http;

const String apiUrl = "https://interpret-208a65c05ca5.herokuapp.com";

Future<Map<String, dynamic>> register(String email, String password) async {
  try {
    var checkResponse = await http.post(
      Uri.parse("$apiUrl/check_user_existing"),
      body: jsonEncode({'email': email}),
      headers: {'Content-Type': 'application/json'},
    );

    if (checkResponse.statusCode == 400) {
      var checkData = jsonDecode(utf8.decode(checkResponse.bodyBytes));
      return {'success': false, 'message': checkData['message']};
    }

    if (checkResponse.statusCode == 200) {
      var response = await http.post(
        Uri.parse("$apiUrl/register"),
        body: jsonEncode({'email': email, 'password': password}),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(utf8.decode(response.bodyBytes));
        return {'success': true, 'message': data['message']};
      } else {
        var data = jsonDecode(utf8.decode(response.bodyBytes));
        return {'success': false, 'message': data['message']};
      }
    }

    return {'success': false, 'message': "Неизвестная ошибка"};
  } catch (e) {
    return {'success': false, 'message': "Ошибка HTTP запроса: $e"};
  }
}

Future<Map<String, dynamic>> login(String email, String password) async {
  try {
    var response = await http.post(
      Uri.parse("$apiUrl/login"),
      body: jsonEncode({'email': email, 'password': password}),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(utf8.decode(response.bodyBytes));
      return {'success': true, 'message': data['message']};
    } else {
      var data = jsonDecode(utf8.decode(response.bodyBytes));
      return {'success': false, 'message': data['message']};
    }
  } catch (e) {
    return {'success': false, 'message': "Ошибка HTTP запроса: $e"};
  }
}
