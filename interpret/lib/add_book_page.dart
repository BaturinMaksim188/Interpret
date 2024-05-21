import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';

const String apiUrl = "https://interpret-208a65c05ca5.herokuapp.com";

class Book {
  final String id;
  final String title;

  Book({required this.id, required this.title});

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'],
      title: json['title'],
    );
  }
}

class BooksPage extends StatefulWidget {
  final String email;
  final String password;

  BooksPage({required this.email, required this.password});

  @override
  _BooksPageState createState() => _BooksPageState();
}

class _BooksPageState extends State<BooksPage> {
  List<Book> _books = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBooks();
  }

  Future<void> _fetchBooks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      var response = await http.get(
        Uri.parse('$apiUrl/get_books'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        List<Book> books = (jsonDecode(response.body) as List)
            .map((data) => Book.fromJson(data))
            .toList();

        setState(() {
          _books = books;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Ошибка загрузки книг")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Ошибка сети, попробуйте позже")));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteBook(String title) async {
    try {
      var response = await http.post(
        Uri.parse('$apiUrl/delete_book'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': widget.email,
          'password': widget.password,
          'title': title,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _books.removeWhere((book) => book.title == title);
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Книга удалена!")));
      } else {
        var data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'])));
        setState(() {
          _books.removeWhere((book) => book.title == title);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Ошибка сети, попробуйте позже")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Мои книги'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _books.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(_books[index].title),
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () => _deleteBook(_books[index].id),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          bool? result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddBookPage(email: widget.email, password: widget.password),
            ),
          );

          if (result == true) {
            _fetchBooks();
          }
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

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

    if (status.isDenied) {
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
      String fileExtension = _selectedFile!.path.split('.').last;

      var request = http.MultipartRequest('POST', Uri.parse('$apiUrl/add_book'))
        ..fields['email'] = widget.email
        ..fields['password'] = widget.password
        ..fields['title'] = _titleController.text
        ..fields['extension'] = fileExtension
        ..files.add(await http.MultipartFile.fromPath('content', _selectedFile!.path));

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var data = jsonDecode(responseData);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Книга добавлена!")));
        Navigator.pop(context, true);
      } else {
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
              Text('Только fb2, pdf или txt файлы.', style: TextStyle(fontSize: 24)),
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
