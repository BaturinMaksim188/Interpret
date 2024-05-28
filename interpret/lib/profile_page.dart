import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

const String apiUrl = "https://interpret-208a65c05ca5.herokuapp.com";

class ProfilePage extends StatefulWidget {
  final String email;
  final String password; // Добавьте password

  ProfilePage({required this.email, required this.password}); // Обновите конструктор

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String selectedLanguage = 'English';
  List<String> languages = ['English', 'Spanish', 'French', 'German'];
  List<String> filteredLanguages = [];

  @override
  void initState() {
    super.initState();
    filteredLanguages = languages;
  }

  void _filterLanguages(String query) {
    setState(() {
      filteredLanguages = languages
          .where((language) => language.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _showLanguagePicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Выбранный язык'),
          content: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search language',
                  ),
                  onChanged: _filterLanguages,
                ),
                Expanded(
                  child: ListView(
                    shrinkWrap: true,
                    children: filteredLanguages
                        .map((language) => ListTile(
                      title: Text(language),
                      onTap: () {
                        _changeLanguage(language);
                        Navigator.of(context).pop();
                      },
                    ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _changeLanguage(String language) async {
    setState(() {
      selectedLanguage = language;
    });

    // Показать экран загрузки
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    // Отправить запрос на изменение языка
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/change_translation_language'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.email,
          'password': widget.password, // Добавьте password в запрос
          'language': language
        }),
      );

      Navigator.of(context).pop(); // Закрыть экран загрузки

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Язык перевода изменен!'),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Ошибка при смене языка'),
        ));
      }
    } catch (e) {
      Navigator.of(context).pop(); // Закрыть экран загрузки
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Ошибка сети'),
      ));
    }
  }

  void _logout() {
    // Add your logout logic here
    Navigator.of(context).popUntil((route) => route.isFirst);
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Профиль'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              widget.email,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            ListTile(
              title: Text('Язык перевода'),
              subtitle: Text(selectedLanguage),
              onTap: _showLanguagePicker,
            ),
            Spacer(),
            TextButton(
              onPressed: _logout,
              child: Text(
                'Выйти',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
