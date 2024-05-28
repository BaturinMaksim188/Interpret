import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
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
  OverlayEntry? _overlayEntry;
  String? _highlightedSentence;

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
    _overlayEntry?.remove();
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
          _bookPages = paginateContent(data['content'], 1000);
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
      if (content[endIndex - 1] == '.') {
        pages.add(content.substring(startIndex, endIndex));
      } else {
        int lastIndex = content.lastIndexOf('.', endIndex);
        if (lastIndex > startIndex) {
          endIndex = lastIndex + 1;
        }
        pages.add(content.substring(startIndex, endIndex));
      }
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

  void _showTranslationOverlay(BuildContext context, String sentence, Offset position) {
    if (_overlayEntry != null) {
      _overlayEntry?.remove();
      _overlayEntry = null;
    }

    setState(() {
      _highlightedSentence = sentence;
    });

    _overlayEntry = _createOverlayEntry(context, sentence, position);
    Overlay.of(context)?.insert(_overlayEntry!);
  }

  OverlayEntry _createOverlayEntry(BuildContext context, String sentence, Offset position) {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    Size size = renderBox.size;
    double dx = position.dx;
    double dy = position.dy;

    const double overlayWidth = 220;
    const double overlayHeight = 120;

    if (dx + overlayWidth > size.width) {
      dx = size.width - overlayWidth - 10;
    }

    if (dy + overlayHeight > size.height) {
      dy = size.height - overlayHeight - 10;
    }

    return OverlayEntry(
      builder: (context) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          _overlayEntry?.remove();
          _overlayEntry = null;
          setState(() {
            _highlightedSentence = null;
          });
        },
        child: Stack(
          children: [
            Positioned(
              left: dx,
              top: dy,
              child: GestureDetector(
                onTap: () {},
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: overlayWidth,
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$sentence',
                          style: TextStyle(fontSize: 16),
                        ),
                        Align(
                          alignment: Alignment.topRight,
                          child: IconButton(
                            icon: Icon(Icons.close),
                            onPressed: () {
                              _overlayEntry?.remove();
                              _overlayEntry = null;
                              setState(() {
                                _highlightedSentence = null;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<TextSpan> _buildTextSpans(String text) {
    List<TextSpan> spans = [];
    RegExp sentenceRegex = RegExp(r'([^.!?]*[.!?])');
    Iterable<RegExpMatch> matches = sentenceRegex.allMatches(text);

    for (RegExpMatch match in matches) {
      String sentence = match.group(0)!;
      spans.add(
        TextSpan(
          text: sentence,
          style: TextStyle(
            fontSize: 18,
            backgroundColor: _highlightedSentence == sentence ? Colors.yellow : Colors.transparent,
          ),
          recognizer: TapGestureRecognizer()
            ..onTapUp = (details) {
              RenderBox box = context.findRenderObject() as RenderBox;
              Offset position = box.localToGlobal(details.globalPosition);
              _showTranslationOverlay(context, sentence, position);
            },
        ),
      );
    }

    return spans;
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
          return LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                onTapUp: (details) {
                  Offset position = details.globalPosition;
                  String tappedSentence = _getTappedSentence(details.localPosition, index);
                  if (tappedSentence.isNotEmpty) {
                    _showTranslationOverlay(context, tappedSentence, position);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(color: Colors.black),
                        children: _buildTextSpans(_bookPages[index]),
                      ),
                    ),
                  ),
                ),
              );
            },
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

  String _getTappedSentence(Offset position, int pageIndex) {
    String text = _bookPages[pageIndex];
    List<String> sentences = text.split('. ');

    for (String sentence in sentences) {
      if (sentence.contains(position.toString())) {
        return sentence;
      }
    }

    return '';
  }
}
