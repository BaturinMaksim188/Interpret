import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

const String apiUrl = "https://interpret-208a65c05ca5.herokuapp.com";

class ConfirmationPage extends StatefulWidget {
  final String email;

  ConfirmationPage({required this.email});

  @override
  _ConfirmationPageState createState() => _ConfirmationPageState();
}

class _ConfirmationPageState extends State<ConfirmationPage> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  int _start = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_start == 0) {
        timer.cancel();
      } else {
        setState(() {
          _start--;
        });
      }
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> validateAndSubmit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      print("Введённый код: ${_codeController.text}");

      try {
        final response = await http.post(
          Uri.parse('$apiUrl/check_code'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(<String, String>{
            'email': widget.email,
            'check_code': _codeController.text,
          }),
        );

        if (response.statusCode == 200) {
          _saveLoginStatus();
          Navigator.of(context).pushReplacementNamed('/home');
        } else {
          final responseJson = jsonDecode(utf8.decode(response.bodyBytes));
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(responseJson['message'].toString())));
        }
      } catch (e) {
        print('Error occurred: $e');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка сети, попробуйте позже')));
      }
    }
  }

  Future<void> remakeCode() async {
    if (widget.email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Email не должен быть пустым')));
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$apiUrl/remake_code'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'email': widget.email,
        }),
      );

      if (response.statusCode == 200) {
        final responseJson = jsonDecode(utf8.decode(response.bodyBytes));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(responseJson['message'].toString())));
        setState(() {
          _start = 60;
        });
        startTimer();
      } else {
        final responseJson = jsonDecode(utf8.decode(response.bodyBytes));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(responseJson['message'].toString())));
      }
    } catch (e) {
      print('Error occurred: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка сети, попробуйте позже')));
    }
  }

  Future<void> _saveLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isLoggedIn', true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Подтверждение кода'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                TextFormField(
                  controller: _codeController,
                  decoration: InputDecoration(labelText: 'Введите код подтверждения'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Пожалуйста, введите код';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: validateAndSubmit,
                  child: Text('Подтвердить'),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _start == 0 ? () {
                    remakeCode();
                  } : null,
                  child: Text(_start == 0 ? 'Отправить код повторно' : 'Повторная отправка через $_start сек.'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
