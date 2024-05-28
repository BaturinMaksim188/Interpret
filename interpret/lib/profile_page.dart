import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  final String email;

  ProfilePage({required this.email});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String selectedLanguage = 'English';

  void _showLanguagePicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Выбранный язык'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search language',
                ),
              ),
              Expanded(
                child: ListView(
                  children: ['English', 'Spanish', 'French', 'German']
                      .map((language) => ListTile(
                    title: Text(language),
                    onTap: () {
                      setState(() {
                        selectedLanguage = language;
                      });
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
    );
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
