import 'package:flutter/material.dart';
import 'auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'confirmation_page.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  bool isLogin = true;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  void _toggleForm() {
    setState(() {
      isLogin = !isLogin;
    });
  }

  void _submit() {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    final isValid = _formKey.currentState!.validate();
    if (!isValid) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final email = _emailController.text.toLowerCase();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (isLogin) {
      login(email, password).then((result) {
        setState(() {
          _isLoading = false;
        });
        if (result['success']) {
          _saveLoginStatus(email, password);
          Navigator.of(context).pushReplacementNamed('/home', arguments: {
            'email': email,
            'password': password,
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'])));
        }
      });
    } else {
      if (password != confirmPassword) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Пароли не совпадают"),
          backgroundColor: Colors.red,
        ));
        return;
      }
      register(email, password).then((result) {
        setState(() {
          _isLoading = false;
        });
        if (result['success']) {
          _saveRegistrationDetails(email, password);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ConfirmationPage(email: email),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'])));
        }
      });
    }
  }

  Future<void> _saveLoginStatus(String email, String password) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isLoggedIn', true);
    prefs.setString('email', email);
    prefs.setString('password', password);
  }

  Future<void> _saveRegistrationDetails(String email, String password) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('email', email);
    prefs.setString('password', password);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isLogin ? 'Вход' : 'Регистрация'),
        leading: isLogin ? null : IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            _toggleForm();
          },
        ),
        actions: [
          TextButton(
            onPressed: _toggleForm,
            child: Text(isLogin ? 'Регистрация' : 'Вход', style: TextStyle(color: Colors.black)),
          )
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _isLoading
              ? CircularProgressIndicator()
              : Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => value!.isEmpty || !value.contains('@') ? 'Введите действительный email' : null,
                ),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Пароль',
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  obscureText: _obscurePassword,
                  validator: (value) => value!.isEmpty || value.length < 6 ? 'Пароль должен быть длиннее 6 символов' : null,
                ),
                if (!isLogin)
                  TextFormField(
                    controller: _confirmPasswordController,
                    decoration: InputDecoration(
                      labelText: 'Повторите пароль',
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                    ),
                    obscureText: _obscureConfirmPassword,
                    validator: (value) => value != _passwordController.text ? 'Пароли не совпадают' : null,
                  ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? CircularProgressIndicator()
                      : Text(isLogin ? 'Войти' : 'Зарегистрироваться'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
