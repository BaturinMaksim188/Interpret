import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String apiUrl = "https://interpret-208a65c05ca5.herokuapp.com";

class ProfilePage extends StatefulWidget {
  final String email;
  final String password;

  ProfilePage({required this.email, required this.password});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String selectedLanguage = 'Russian';
  List<String> languages = [
    'English',
    'Spanish',
    'French',
    'German',
    'Chinese (Simplified)',
    'Japanese',
    'Korean',
    'Russian',
    'Portuguese',
    'Italian',
    'Dutch',
    'Arabic',
    'Turkish',
    'Polish',
    'Swedish',
    'Danish',
    'Norwegian',
    'Finnish',
    'Greek',
    'Czech'
  ];
  List<String> filteredLanguages = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSelectedLanguage();
    filteredLanguages = languages;
  }

  void _loadSelectedLanguage() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$apiUrl/get_translation_language'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.email,
          'password': widget.password,
        }),
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        setState(() {
          selectedLanguage = responseBody['content'];
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Ошибка при загрузке языка перевода'),
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Ошибка сети'),
      ));
    }

    setState(() {
      isLoading = false;
    });
  }

  void _saveSelectedLanguage(String language) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedLanguage', language);
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
          title: Text('Выберите язык'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Container(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Найти',
                      ),
                      onChanged: (value) {
                        setState(() {
                          _filterLanguages(value);
                        });
                      },
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
              );
            },
          ),
        );
      },
    );
  }

  void _changeLanguage(String language) async {
    setState(() {
      selectedLanguage = language;
    });

    _saveSelectedLanguage(language);

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
          'password': widget.password,
          'language': language
        }),
      );

      Navigator.of(context).pop();

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
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Ошибка сети'),
      ));
    }
  }

  void _logout() {
    Navigator.of(context).popUntil((route) => route.isFirst);
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Профиль'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
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
