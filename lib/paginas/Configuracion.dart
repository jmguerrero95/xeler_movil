import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xeler_impresora/api/api.dart';
import 'package:xeler_impresora/paginas/Login.dart';
import 'package:xeler_impresora/paginas/Seleccion2.dart';

import 'Cambiar.dart';

const TextStyle whiteBoldText = TextStyle(
  fontWeight: FontWeight.bold,
  color: Colors.black,
);

class ConfiguracionPage extends StatefulWidget {
  const ConfiguracionPage({super.key, this.title});

  final String? title;

  @override
  State<ConfiguracionPage> createState() => _ConfiguracionState();
}

class _ConfiguracionState extends State<ConfiguracionPage> {
  Map<String, dynamic>? userData;
  String? elDispositivo;

  final TextStyle greyText = TextStyle(
    color: Colors.grey.shade400,
  );

  @override
  void initState() {
    super.initState();
    _getUserInfo();
  }

  Future<void> _getUserInfo() async {
    final localStorage = await SharedPreferences.getInstance();
    final userJson = localStorage.getString('user');
    if (userJson == null) {
      if (!mounted) return;
      setState(() {
        userData = null;
        elDispositivo = null;
      });
      return;
    }
    final user = jsonDecode(userJson) as Map<String, dynamic>;
    if (!mounted) return;
    setState(() {
      userData = user;
      elDispositivo = user['dispositivo']?.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/512xeler.png',
              fit: BoxFit.contain,
              height: 32,
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            ListTile(
              title: const Text(
                'Impresora Seleccionada',
                style: whiteBoldText,
              ),
              subtitle: Text(
                elDispositivo ?? 'Ninguna',
                style: greyText,
              ),
              trailing: Icon(
                Icons.keyboard_arrow_right,
                color: Colors.grey.shade400,
              ),
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SeleccionPage2(),
                  ),
                );
                _getUserInfo();
              },
            ),
            const Divider(
              color: Colors.black,
              height: 5,
            ),
            ListTile(
              title: const Text(
                'Cambiar Contraseña',
                style: whiteBoldText,
              ),
              trailing: Icon(
                Icons.keyboard_arrow_right,
                color: Colors.grey.shade400,
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const CambiarPage(),
                  ),
                );
              },
            ),
            const Divider(
              color: Colors.black,
              height: 5,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> logout() async {
    final res = await CallApi().getData('logout');
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (body['success'] == true) {
      final localStorage = await SharedPreferences.getInstance();
      await localStorage.remove('user');
      await localStorage.remove('token');
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const LogIn(),
        ),
      );
    }
  }
}
