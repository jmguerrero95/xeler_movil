import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xeler_impresora/api/api.dart';
import 'package:xeler_impresora/model/Facturas.dart';
import 'package:xeler_impresora/paginas/CrearFactura.dart';
import 'package:xeler_impresora/paginas/testprint.dart';

class DetallesCliente extends StatefulWidget {
  const DetallesCliente({super.key, required this.id, required this.name});

  final int id;
  final String name;

  @override
  State<DetallesCliente> createState() => _DetallesClienteState();
}

class _DetallesClienteState extends State<DetallesCliente> {
  final BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
  final TestPrint testPrint = TestPrint();
  final NumberFormat formato = NumberFormat('#,###');

  final List<Facturas> _ultimos = [];
  String? pathImage;
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    initSavetoPath();
    initPlatformState();
    _getUserInfo();
    _loadFacturas();
  }

  Future<void> _loadFacturas() async {
    try {
      final response = await CallApi().getData('obtenerFacturasCliente/${widget.id}');
      if (response.statusCode == 200) {
        final List<dynamic> notesJson = jsonDecode(response.body) as List<dynamic>;
        final facturas = notesJson
            .map((noteJson) => Facturas.fromJson(noteJson as Map<String, dynamic>))
            .toList();
        if (!mounted) return;
        setState(() {
          _ultimos
            ..clear()
            ..addAll(facturas);
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _ultimos.clear();
      });
    }
  }

  Future<void> _getUserInfo() async {
    final localStorage = await SharedPreferences.getInstance();
    final userJson = localStorage.getString('user');
    if (!mounted) return;
    setState(() {
      userData = userJson != null
          ? jsonDecode(userJson) as Map<String, dynamic>
          : null;
    });
  }

  Future<void> writeToFile(ByteData data, String path) {
    final buffer = data.buffer;
    return File(path).writeAsBytes(
      buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
  }

  Future<void> initPlatformState() async {
    bluetooth.onStateChanged().listen((state) {
      switch (state) {
        case BlueThermalPrinter.CONNECTED:
        case BlueThermalPrinter.DISCONNECTED:
        default:
          break;
      }
    });

    if (!mounted) return;
  }

  Future<void> initSavetoPath() async {
    const filename = '192xeler.png';
    final bytes = await rootBundle.load('assets/images/192xeler.png');
    final dir = (await getApplicationDocumentsDirectory()).path;
    final fullPath = '$dir/$filename';
    await writeToFile(bytes, fullPath);
    if (mounted) {
      setState(() {
        pathImage = fullPath;
      });
    }
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
        child: Padding(
          padding: const EdgeInsets.only(top: 0.0, left: 0.0, right: 0.0),
          child: Column(
            children: <Widget>[
              ProfileHeader(
                title: widget.name,
                actions: <Widget>[
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.deepPurpleAccent,
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => CrearFacturaPage(
                            id: widget.id,
                            name: widget.name,
                          ),
                        ),
                      );
                    },
                  )
                ],
              ),
              const SizedBox(height: 10.0),
              Container(
                width: double.infinity,
                height: 690,
                margin: const EdgeInsets.only(top: 15),
                child: Column(
                  children: <Widget>[
                    Row(
                      children: const <Widget>[
                        Padding(
                          padding: EdgeInsets.only(top: 0.0, left: 20),
                          child: Text(
                            'Últimas 5 Facturas',
                            style: TextStyle(fontSize: 18.0),
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: _ultimos.isNotEmpty
                          ? ListView.builder(
                              itemBuilder: (context, index) {
                                final factura = _ultimos[index];
                                return Card(
                                  elevation: 8.0,
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Color.fromARGB(255, 36, 38, 80),
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 20.0,
                                        vertical: 10.0,
                                      ),
                                      title: Text(
                                        'Valor: COP ${formato.format(int.parse(factura.valor))}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Row(
                                        children: <Widget>[
                                          Expanded(
                                            flex: 4,
                                            child: Padding(
                                              padding: const EdgeInsets.only(left: 4.0),
                                              child: Text(
                                                'Wallet destino: ${factura.primeros} / ${factura.ultimos}',
                                                style: const TextStyle(color: Colors.white),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      onTap: () {
                                        final direccion = userData?['direccion']?.toString() ??
                                            userData?['address']?.toString();
                                        final imagePath = pathImage;
                                        if (direccion != null && imagePath != null) {
                                          testPrint.sample2(
                                            imagePath,
                                            direccion,
                                            factura.id.toString(),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                );
                              },
                              itemCount: _ultimos.length,
                            )
                          : Center(
                              child: Text(
                                'El cliente ${widget.name} no tiene facturas',
                                style: const TextStyle(fontSize: 18.0),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key, required this.title, this.subtitle, this.actions});

  final String title;
  final String? subtitle;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Ink(
          height: 80,
          decoration: const BoxDecoration(
            color: Color.fromARGB(255, 36, 38, 80),
          ),
        ),
        if (actions != null)
          Container(
            width: double.infinity,
            height: 60,
            padding: const EdgeInsets.only(bottom: 0.0, right: 0.0),
            alignment: Alignment.bottomRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: actions!,
            ),
          ),
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 30),
          child: Column(
            children: <Widget>[
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: const TextStyle(color: Colors.white70),
                ),
            ],
          ),
        )
      ],
    );
  }
}
