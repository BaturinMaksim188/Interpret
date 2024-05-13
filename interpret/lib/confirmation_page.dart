import 'package:flutter/material.dart';

class ConfirmationPage extends StatefulWidget {
  @override
  _ConfirmationPageState createState() => _ConfirmationPageState();
}

class _ConfirmationPageState extends State<ConfirmationPage> {
  final _formKey = GlobalKey<FormState>(); // Ключ для управления формой
  final _codeController = TextEditingController(); // Контроллер для текстового поля кода
  int _start = 60; // Начальное значение таймера

  void startTimer() {
    const oneSec = const Duration(seconds: 1);
    setState(() {
      if (_start > 0) {
        _start--;
      }
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void validateAndSubmit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      // Здесь можно добавить логику отправки кода на сервер или его проверки
      print("Введённый код: ${_codeController.text}");
      // Предположим, код должен быть "1234"
      if (_codeController.text == "1234") {
        Navigator.of(context).pushReplacementNamed('/home'); // Переход на домашнюю страницу
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Неверный код')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Подтверждение кода'),
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
                    startTimer(); /* отправить код повторно */
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
