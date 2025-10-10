import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xeler_impresora/api/api.dart';
import 'package:xeler_impresora/paginas/Clientes.dart';
import 'package:xeler_impresora/paginas/Configuracion.dart';
import 'package:xeler_impresora/paginas/Home.dart';
import 'package:xeler_impresora/paginas/Resumen.dart';
import 'package:xeler_impresora/paginas/Login.dart';

class Inicio extends StatefulWidget {
  const Inicio({super.key});

  @override
  State<Inicio> createState() => _InicioState();
}

class _InicioState extends State<Inicio> {
  final List<Widget> _pages = const [
    HomePage(),
    ClientesPage(),
    ResumenPage(),
    ConfiguracionPage(),
  ];

  int _index = 0;
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    _getUserInfo();
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  Future<void> _getUserInfo() async {
    final localStorage = await SharedPreferences.getInstance();
    final userJson = localStorage.getString('user');
    if (userJson == null) {
      if (!mounted) return;
      setState(() {
        userData = null;
      });
      return;
    }

    final user = jsonDecode(userJson) as Map<String, dynamic>;
    if (!mounted) return;
    setState(() {
      userData = user;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color.fromARGB(255, 36, 38, 80),
        unselectedItemColor: Colors.grey.shade600,
        onTap: (position) {
          setState(() {
            _index = position;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.supervisor_account),
            label: 'Clientes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.monetization_on),
            label: 'Resumen',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Configuración',
          ),
        ],
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
        MaterialPageRoute<void>(
          builder: (context) => const LogIn(),
        ),
      );
    }
  }
}
