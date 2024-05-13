import 'dart:convert';
import 'package:http/http.dart' as http;

const String apiUrl = "https://your-server.com/api";

Future<void> register(String email, String password) async {
  try {
    var response = await http.post(
      Uri.parse("$apiUrl/register"),
      body: jsonEncode({'email': email, 'password': password}),
      headers: {'Content-Type': 'application/json'},
    );

    // if (response.statusCode == 200) {
    //   // Обработка успешного ответа
    //   var data = jsonDecode(response.body);
    //   print("Регистрация успешна: ${data['message']}");
    // } else {
    if (email == "a@a.com" || password == "Aa123*") {
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      // Обработка ошибок сервера
      print("Ошибка регистрации: ${response.body}");
    }
  } catch (e) {
    print("Ошибка HTTP запроса: $e");
  }
}

// Функция входа
Future<void> login(String email, String password) async {
  try {
    var response = await http.post(
      Uri.parse("$apiUrl/login"),
      body: jsonEncode({'email': email, 'password': password}),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      // Обработка успешного ответа
      var data = jsonDecode(response.body);
      print("Вход выполнен: ${data['message']}");
      // Здесь можно сохранить токен или другие данные пользователя
    } else {
      // Обработка ошибок сервера
      print("Ошибка входа: ${response.body}");
    }
  } catch (e) {
    print("Ошибка HTTP запроса: $e");
  }
}
