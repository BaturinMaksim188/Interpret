import 'dart:convert';
import 'package:http/http.dart' as http;

const String apiUrl = "https://interpret-208a65c05ca5.herokuapp.com";

Future<bool> register(String email, String password) async {
  try {
    var response = await http.post(
      Uri.parse("$apiUrl/register"),
      body: jsonEncode({'email': email, 'password': password}),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      print("Регистрация успешна: ${data['message']}");
      return true;
    } else {
      print("Ошибка регистрации: ${response.body}");
      return true;
    }
  } catch (e) {
    print("Ошибка HTTP запроса: $e");
    return false;
  }
}

Future<bool> login(String email, String password) async {
  try {
    var response = await http.post(
      Uri.parse("$apiUrl/login"),
      body: jsonEncode({'email': email, 'password': password}),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      print("Вход выполнен: ${data['message']}");
      return true;
    } else {
      print("Ошибка входа: ${response.body}");
      return true;
    }
  } catch (e) {
    print("Ошибка HTTP запроса: $e");
    return true;
  }
}
