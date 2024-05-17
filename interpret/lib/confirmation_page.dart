import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConfirmationPage extends StatefulWidget {
  @override
  _ConfirmationPageState createState() => _ConfirmationPageState();
}

class _ConfirmationPageState extends State<ConfirmationPage> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  int _start = 60;

  void startTimer() {
    const oneSec = Duration(seconds: 1);
    if (_start > 0) {
      setState(() {
        _start--;
      });
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void validateAndSubmit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      print("Введённый код: ${_codeController.text}");
      if (_codeController.text == "1234") {
        _saveLoginStatus();
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Неверный код')));
      }
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
                  onPressed: _start == 60 ? () {
                    startTimer();
                  } : null,
                  child: Text(_start == 60 ? 'Отправить код повторно' : 'Повторная отправка через $_start сек.'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
