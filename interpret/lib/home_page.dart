import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'add_book_page.dart';
import 'read_page.dart';  // Импортируйте read_page

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
      _message = '';
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

  Future<void> _deleteBook(String bookTitle) async {
    setState(() {
      _isLoading = true;
    });

    try {
      var response = await http.post(
        Uri.parse("$apiUrl/delete_book"),
        body: jsonEncode({
          'email': widget.email,
          'password': widget.password,
          'title': bookTitle,
        }),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200 || response.statusCode == 500) {
        setState(() {
          _books.remove(bookTitle);
          _filteredBooks.remove(bookTitle);
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Книга удалена!")));
        await _loadBooks();  // Обновляем список книг после удаления
      } else {
        var data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'])));
      }
    } catch (e) {
      setState(() {
        _message = "Ошибка сети, попробуйте позже";
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Ошибка сети, попробуйте позже")));
    }
  }

  void _addBook() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddBookPage(email: widget.email, password: widget.password),
      ),
    );
    if (result == true) {
      _loadBooks();
    }
  }

  void _readBook(String bookTitle) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReadPage(
          bookTitle: bookTitle,
          email: widget.email,
          password: widget.password,
        ),
      ),
    );
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
        title: Text('Книги'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => _logout(context),
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
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Поиск книги',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredBooks.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_filteredBooks[index]),
                  onTap: () => _readBook(_filteredBooks[index]),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () => _deleteBook(_filteredBooks[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addBook,
        child: Icon(Icons.add),
      ),
    );
  }
}
