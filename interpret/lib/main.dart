import 'package:flutter/material.dart';
import 'login_page.dart';
import 'confirmation_page.dart';
import 'home_page.dart';
import 'read_page.dart';  // Импортируйте read_page
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Interpret',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (context) => CheckAuth());
          case '/login':
            return MaterialPageRoute(builder: (context) => LoginPage());
          case '/home':
            final args = settings.arguments as Map<String, String?>;
            if (args['email'] != null && args['password'] != null) {
              return MaterialPageRoute(
                builder: (context) => HomePage(
                  email: args['email']!,
                  password: args['password']!,
                ),
              );
            } else {
              return MaterialPageRoute(builder: (context) => LoginPage());
            }
          case '/read':
            final args = settings.arguments as Map<String, String>;
            return MaterialPageRoute(
              builder: (context) => ReadPage(
                bookTitle: args['bookTitle']!,
                email: args['email']!,
                password: args['password']!,
              ),
            );
          default:
            return MaterialPageRoute(builder: (context) => LoginPage());
        }
      },
    );
  }
}

class CheckAuth extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: checkLoginStatus(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasData && snapshot.data == true) {
          return FutureBuilder<Map<String, String>>(
            future: getUserCredentials(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              } else if (snapshot.hasData) {
                return HomePage(
                  email: snapshot.data!['email']!,
                  password: snapshot.data!['password']!,
                );
              } else {
                return LoginPage();
              }
            },
          );
        } else {
          return LoginPage();
        }
      },
    );
  }

  Future<bool> checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  Future<Map<String, String>> getUserCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email') ?? '';
    final password = prefs.getString('password') ?? '';
    return {'email': email, 'password': password};
  }
}
