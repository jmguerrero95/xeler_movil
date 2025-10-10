import 'dart:convert';

import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xeler_impresora/paginas/Inicio.dart';
import 'package:xeler_impresora/paginas/Login.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
  bool _isLoggedIn = false;
  Map<String, dynamic>? userData;
  int? _tipo;
  String? _dispositivo;
  String? _direccion;

  @override
  void initState() {
    super.initState();
    _checkIfLoggedIn();
  }

  @override
  void dispose() {
    bluetooth.dispose();
    super.dispose();
  }

  Future<void> _checkIfLoggedIn() async {
    final localStorage = await SharedPreferences.getInstance();
    final token = localStorage.getString('token');
    final userJson = localStorage.getString('user');
    if (token == null || userJson == null) {
      setState(() {
        _isLoggedIn = false;
        userData = null;
      });
      return;
    }

    final decoded = jsonDecode(userJson) as Map<String, dynamic>;
    final dispositivo = decoded['dispositivo']?.toString();
    final direccion =
        (decoded['address'] ?? decoded['direccion'])?.toString();
    final tipoRaw = decoded['tipo'];

    setState(() {
      _isLoggedIn = true;
      userData = decoded;
      _dispositivo = dispositivo;
      _direccion = direccion;
      _tipo = tipoRaw is int ? tipoRaw : int.tryParse('$tipoRaw');
    });

    if (_direccion == null || _dispositivo == null || _tipo == null) {
      return;
    }

    final device = BluetoothDevice.fromMap({
      'name': _dispositivo,
      'address': _direccion,
      'type': _tipo,
    });

    final isConnected = await bluetooth.isConnected;
    if (isConnected != true) {
      try {
        await bluetooth.connect(device);
      } catch (_) {
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es'),
      ],
      theme: ThemeData(
        primaryColor: const Color.fromARGB(255, 36, 38, 80),
        fontFamily: 'Raleway',
      ),
      home: Scaffold(
        body: _isLoggedIn ? const Inicio() : const LogIn(),
      ),
    );
  }
}
