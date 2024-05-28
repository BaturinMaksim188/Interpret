import 'package:flutter/material.dart';
import 'profile_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'add_book_page.dart';
import 'read_page.dart';

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
        title: Text('Домашняя страница'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.account_circle),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfilePage(email: widget.email, password: widget.password)),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _books.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Добавьте первую книгу', style: TextStyle(color: Colors.blue)),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadBooks,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Поиск книги',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
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
                      _readBook(_filteredBooks[index]);
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addBook,
        child: Icon(Icons.add),
      ),
    );
  }
}
