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

  @override
  void initState() {
    super.initState();
    _clearSavedFile();
  }

  Future<void> _clearSavedFile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('selected_file');
    setState(() {
      _selectedFile = null;
      _titleController.clear();
    });
  }

  Future<void> _pickFile() async {
    PermissionStatus status = await Permission.storage.request();
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['fb2', 'pdf', 'txt'],
    );

    if (result != null) {
      String fileExtension = result.files.single.extension!;
      if (!['fb2', 'pdf', 'txt'].contains(fileExtension.toLowerCase())) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Вы можете загружать только fb2, pdf или txt файлы.")));
        return;
      }

      setState(() {
        _selectedFile = File(result.files.single.path!);
        String fileName = _selectedFile!.path.split('/').last;
        String bookTitle = fileName.split('.').first;
        _titleController.text = bookTitle;
      });

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_file', _selectedFile!.path);
    }
    // if (status.isDenied) {
    //   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Разрешение на доступ к хранилищу отклонено.")));
    // } else if (status.isPermanentlyDenied) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(
    //       content: Text("Разрешение на доступ к хранилищу постоянно отклонено. Пожалуйста, измените это в настройках."),
    //       action: SnackBarAction(
    //         label: 'Настройки',
    //         onPressed: openAppSettings,
    //       ),
    //     ),
    //   );
    // }
  }

  Future<void> _addBook() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? filePath = prefs.getString('selected_file');
        if (filePath == null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Выберите файл для загрузки.")));
          setState(() {
            _isLoading = false;
          });
          return;
        }

        File file = File(filePath);
        String fileExtension = file.path.split('.').last;

        var request = http.MultipartRequest('POST', Uri.parse('$apiUrl/add_book'))
          ..fields['email'] = widget.email
          ..fields['password'] = widget.password
          ..fields['title'] = _titleController.text
          ..fields['extension'] = fileExtension
          ..files.add(await http.MultipartFile.fromPath('content', file.path));

        var response = await request.send();

        if (response.statusCode == 200) {
          var responseData = await response.stream.bytesToString();
          var data = jsonDecode(responseData);

          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Книга добавлена!")));
          Navigator.pop(context, true);
        } else {
          var responseData = await response.stream.bytesToString();
          var data = jsonDecode(responseData);
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'])));
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Ошибка сети, попробуйте позже")));
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Добавить книгу'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Название книги'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Пожалуйста, введите название книги';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _pickFile,
                child: Text('Выбрать файл'),
              ),
              SizedBox(height: 20),
              _selectedFile != null
                  ? Text('Выбран файл: ${_selectedFile!.path.split('/').last}')
                  : Text('Файл не выбран'),
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
