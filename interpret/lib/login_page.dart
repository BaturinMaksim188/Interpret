import 'package:flutter/material.dart';
import 'auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'confirmation_page.dart';

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

  void _toggleForm() {
    setState(() {
      isLogin = !isLogin;
    });
  }

  void _submit() {
    final isValid = _formKey.currentState!.validate();
    if (!isValid) return;

    final email = _emailController.text.toLowerCase();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (isLogin) {
      login(email, password).then((success) {
        if (success) {
          _saveLoginStatus();
          Navigator.of(context).pushReplacementNamed('/home');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Ошибка входа")));
        }
      });
    } else {
      if (password != confirmPassword) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Пароли не совпадают"),
          backgroundColor: Colors.red,
        ));
        return;
      }
      register(email, password).then((success) {
        if (success) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ConfirmationPage(email: email),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Ошибка регистрации")));
        }
      });
    }
  }

  Future<void> _saveLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isLoggedIn', true);
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
          child: Form(
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
                  onPressed: _submit,
                  child: Text(isLogin ? 'Войти' : 'Зарегистрироваться'),
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
