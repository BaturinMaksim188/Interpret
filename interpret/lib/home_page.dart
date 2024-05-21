import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

const String apiUrl = "https://interpret-208a65c05ca5.herokuapp.com";

class HomePage extends StatefulWidget {
  final String email;
  final String password;

  HomePage({required this.email, required this.password});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isLoading = true;
  String _message = '';
  List<String> _books = [];
  List<String> _filteredBooks = [];
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBooks();
    _searchController.addListener(_filterBooks);
  }

  void _filterBooks() {
    setState(() {
      _filteredBooks = _books
          .where((book) =>
          book.toLowerCase().contains(_searchController.text.toLowerCase()))
          .toList();
    });
  }

  Future<void> _loadBooks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      var response = await http.post(
        Uri.parse("$apiUrl/load_books"),
        body: jsonEncode({'email': widget.email, 'password': widget.password}),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _books = List<String>.from(data['content']);
          _filteredBooks = _books;
          _isLoading = false;
        });
      } else {
        var data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _message = data['message'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _message = "Ошибка сети, попробуйте позже";
        _isLoading = false;
      });
    }
  }

  Future<void> _retryLoadBooks() async {
    _loadBooks();
  }

  Future<void> _logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isLoggedIn', false);
    Navigator.of(context).pushReplacementNamed('/login');
  }

  void _deleteBook(String bookTitle) {
    setState(() {
      _books.remove(bookTitle);
      _filteredBooks.remove(bookTitle);
    });
    // Здесь можно добавить запрос на сервер для удаления книги
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Домашняя страница'),
        automaticallyImplyLeading: false, // Отключение стрелки "назад"
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () {
              _logout(context);
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _message.isNotEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_message),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _retryLoadBooks,
              child: Text('Повторить'),
            ),
          ],
        ),
      )
          : _books.isEmpty
          ? Center(
        child: GestureDetector(
          onTap: () {
            // Логика добавления первой книги
            print("Добавление первой книги");
          },
          child: Text(
            'Добавьте первую книгу',
            style: TextStyle(color: Colors.blue),
          ),
        ),
      )
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Поиск',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: _filteredBooks.length,
              separatorBuilder: (context, index) => Divider(),
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_filteredBooks[index]),
                  onTap: () {
                    // Логика при клике на книгу
                    print("Книга выбрана: ${_filteredBooks[index]}");
                  },
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      _deleteBook(_filteredBooks[index]);
                    },
                  ),
                  tileColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Icon(Icons.book, color: Colors.blue),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
