import 'package:flutter/material.dart';
import 'login_page.dart';
import 'confirmation_page.dart';
import 'home_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Название Приложения',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginPage(),
        '/confirm': (context) => ConfirmationPage(),
        // '/home': (context) => HomePage(),
      },
    );
  }
}
