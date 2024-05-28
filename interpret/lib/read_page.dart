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
  TextEditingController _jumpPageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadBookContent();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _jumpPageController.dispose();
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
          _bookPages = paginateContent(data['content'], 1000);  // Разбить текст на страницы по 1000 символов
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

  List<String> paginateContent(String content, int charsPerPage) {
    List<String> pages = [];
    int startIndex = 0;

    while (startIndex < content.length) {
      int endIndex = startIndex + charsPerPage;
      if (endIndex > content.length) {
        endIndex = content.length;
      }
      pages.add(content.substring(startIndex, endIndex));
      startIndex = endIndex;
    }

    return pages;
  }

  Future<void> _jumpToPage() async {
    _jumpPageController.clear();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Введите номер страницы"),
        content: TextField(
          controller: _jumpPageController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: "Номер страницы",
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text("Отмена"),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text("Перейти"),
            onPressed: () {
              int? page = int.tryParse(_jumpPageController.text);
              if (page != null) {
                if (page < 1) page = 1;
                if (page > _bookPages.length) page = _bookPages.length;
                Navigator.of(context).pop();
                _goToPage(page - 1);
              } else {
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
    );
  }

  void _goToPage(int page) {
    _pageController.jumpToPage(page);
    setState(() {
      _currentPage = page;
    });
    _saveCurrentPage(page);
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
          setState(() {
            _currentPage = page;
          });
          _saveCurrentPage(page);
        },
        itemCount: _bookPages.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Text(_bookPages[index]),
            ),
          );
        },
      ),
      bottomNavigationBar: BottomAppBar(
        child: Container(
          height: 50.0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: _currentPage > 0
                    ? () {
                  _pageController.previousPage(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.ease,
                  );
                }
                    : null,
              ),
              GestureDetector(
                onTap: _jumpToPage,
                child: Text('Страница ${_currentPage + 1} из ${_bookPages.length}'),
              ),
              IconButton(
                icon: Icon(Icons.arrow_forward),
                onPressed: _currentPage < _bookPages.length - 1
                    ? () {
                  _pageController.nextPage(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.ease,
                  );
                }
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
