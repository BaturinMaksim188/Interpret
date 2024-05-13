import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Домашняя страница'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // Здесь будет логика для добавления документа
            print("Добавление документа");
          },
          child: Text('Добавить документ'),
        ),
      ),
    );
  }
}
