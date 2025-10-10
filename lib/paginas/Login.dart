import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xeler_impresora/api/api.dart';
import 'package:xeler_impresora/paginas/Inicio.dart';

class LogIn extends StatefulWidget {
  const LogIn({super.key});

  @override
  State<LogIn> createState() => _LogInState();
}

class _LogInState extends State<LogIn> {
  final TextEditingController mailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    mailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          action: SnackBarAction(
            label: 'Cerrar',
            onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final logo = Hero(
      tag: 'hero',
      child: CircleAvatar(
        backgroundColor: Colors.transparent,
        radius: 48.0,
        child: Image.asset('assets/images/512xeler.png'),
      ),
    );

    final email = TextFormField(
      cursorColor: const Color.fromARGB(255, 36, 38, 80),
      keyboardType: TextInputType.emailAddress,
      controller: mailController,
      autofocus: false,
      style: const TextStyle(color: Color(0xFF000000)),
      decoration: InputDecoration(
        hintText: 'Usuario',
        fillColor: Colors.white,
        filled: true,
        contentPadding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(32.0)),
      ),
    );

    final password = TextFormField(
      autofocus: false,
      obscureText: true,
      controller: passwordController,
      style: const TextStyle(color: Color(0xFF000000)),
      decoration: InputDecoration(
        hintText: 'Contraseña',
        fillColor: Colors.white,
        filled: true,
        contentPadding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(32.0),
        ),
      ),
    );

    final loginButton = Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 118, 104, 254),
            padding: const EdgeInsets.all(12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          onPressed: _isLoading ? null : _login,
          child: Text(
            _isLoading ? 'Iniciando...' : 'Iniciar Sesión',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 36, 38, 80),
      body: Center(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(left: 24.0, right: 24.0),
          children: <Widget>[
            logo,
            const SizedBox(height: 48.0),
            email,
            const SizedBox(height: 8.0),
            password,
            const SizedBox(height: 24.0),
            loginButton,
          ],
        ),
      ),
    );
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

    final data = <String, String>{
      'username': mailController.text.trim(),
      'password': passwordController.text,
    };

    try {
      final res = await CallApi().postData(data, 'login');
      final body = jsonDecode(res.body) as Map<String, dynamic>;

      if (body['success'] == true) {
        final localStorage = await SharedPreferences.getInstance();
        final token = body['token']?.toString();
        final user = body['user'];
        if (token != null && user != null) {
          await localStorage.setString('token', token);
          await localStorage.setString('user', jsonEncode(user));
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (context) => const Inicio(),
            ),
          );
        } else {
          _showMsg('Respuesta inválida del servidor.');
        }
      } else {
        final message = body['message']?.toString() ?? 'Credenciales inválidas';
        _showMsg(message);
      }
    } catch (error) {
      _showMsg('Error de conexión: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
