import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

const String apiUrl = "https://interpret-208a65c05ca5.herokuapp.com";

class ReadPage extends StatefulWidget {
  final String bookTitle;
  final String email;
  final String password;

  ReadPage({required this.bookTitle, required this.email, required this.password});

  @override
  _ReadPageState createState() => _ReadPageState();
}

class _ReadPageState extends State<ReadPage> {
  int _currentPage = 0;
  late PageController _pageController;
  List<String> _bookPages = [];
  bool _isLoading = true;
  String _message = '';

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadBookContent();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _saveCurrentPage(int page) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt('lastPage_${widget.bookTitle}', page);

    try {
      var response = await http.post(
        Uri.parse("$apiUrl/save_current_page"),
        body: jsonEncode({
          'email': widget.email,
          'password': widget.password,
          'title': widget.bookTitle,
          'current_page': page,
        }),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        setState(() {
          _message = "Не удалось сохранить текущую страницу.";
        });
      }
    } catch (e) {
      setState(() {
        _message = "Ошибка сети, попробуйте позже";
      });
    }
  }

  Future<void> _loadBookContent() async {
    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      var response = await http.post(
        Uri.parse("$apiUrl/load_book"),
        body: jsonEncode({
          'email': widget.email,
          'password': widget.password,
          'title': widget.bookTitle,
        }),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _bookPages = data['content'].split('\n\n'); // Предполагаем, что страницы разделены двумя новыми строками
          _currentPage = data['current_page'];
          _pageController = PageController(initialPage: _currentPage);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.bookTitle),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _message.isNotEmpty
          ? Center(child: Text(_message))
          : PageView.builder(
        controller: _pageController,
        onPageChanged: (page) {
          _saveCurrentPage(page);
        },
        itemCount: _bookPages.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(_bookPages[index]),
          );
        },
      ),
    );
  }
}