import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';

const String apiUrl = "https://interpret-208a65c05ca5.herokuapp.com";

class AddBookPage extends StatefulWidget {
  final String email;
  final String password;

  AddBookPage({required this.email, required this.password});

  @override
  _AddBookPageState createState() => _AddBookPageState();
}

class _AddBookPageState extends State<AddBookPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  File? _selectedFile;
  bool _isLoading = false;

  Future<void> _pickFile() async {
    PermissionStatus status = await Permission.storage.request();

    if (status.isGranted) {
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          String fileName = _selectedFile!.path.split('/').last;
          String bookTitle = fileName.split('.').first;
          _titleController.text = bookTitle;
        });
      }
    } else if (status.isDenied) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Разрешение на доступ к хранилищу отклонено.")));
    } else if (status.isPermanentlyDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Разрешение на доступ к хранилищу постоянно отклонено. Пожалуйста, измените это в настройках приложения."),
          action: SnackBarAction(
            label: 'Настройки',
            onPressed: () {
              openAppSettings();
            },
          ),
        ),
      );
    }
  }

  Future<void> _addBook() async {
    if (!_formKey.currentState!.validate() || _selectedFile == null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      var request = http.MultipartRequest('POST', Uri.parse('$apiUrl/add_book'))
        ..fields['email'] = widget.email
        ..fields['password'] = widget.password
        ..fields['title'] = _titleController.text
        ..files.add(await http.MultipartFile.fromPath('content', _selectedFile!.path));

      var response = await request.send();

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Книга добавлена!")));
        Navigator.pop(context, true);
      } else {
        var responseData = await response.stream.bytesToString();
        var data = jsonDecode(responseData);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'])));
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Ошибка сети, попробуйте позже")));
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Добавить книгу'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Название книги'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите название книги';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _pickFile,
                child: Text(_selectedFile == null ? 'Выбрать файл' : 'Файл выбран'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _addBook,
                child: Text('Добавить книгу'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
