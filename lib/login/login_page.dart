import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ride_hailing/components/base_scaffold.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  var _showPassword = false;
  var _loading = false;
  String? _errorText;

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _errorText = 'Kedua kolom harus diisi!';
      return;
    }

    _loading = true;
    _errorText = null;
    setState(() {});

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
    } on FirebaseAuthException catch (e) {
      _loading = false;
      _errorText = e.message;
      setState(() {});
    } catch (e) {
      _loading = false;
      _errorText = e.toString();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: 'Login Page',
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Email',
              ),
            ),
            SizedBox(
              height: 8.0,
            ),
            TextField(
              controller: _passwordController,
              obscureText: !_showPassword,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Password',
              ),
            ),
            SizedBox(
              height: 16.0,
            ),
            Container(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _login,
                child: _loading
                    ? Center(
                        widthFactor: 1.0,
                        heightFactor: 1.0,
                        child: SizedBox(
                          height: 16.0,
                          width: 16.0,
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : Text(
                        'Login',
                      ),
              ),
            ),
            if (_errorText?.isNotEmpty ?? false) ...[
              SizedBox(
                height: 16.0,
              ),
              Center(
                child: Text(
                  _errorText ?? 'Something is wrong!',
                  style: TextStyle(
                    color: Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
