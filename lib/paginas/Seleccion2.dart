import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xeler_impresora/api/api.dart';
import 'package:xeler_impresora/paginas/testprint.dart';

class SeleccionPage2 extends StatefulWidget {
  const SeleccionPage2({super.key});

  @override
  State<SeleccionPage2> createState() => _SeleccionPage2State();
}

class _SeleccionPage2State extends State<SeleccionPage2> {
  final BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
  final TestPrint testPrint = TestPrint();

  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _device;
  bool _connected = false;
  Map<String, dynamic>? userData;
  String? _dispositivo;
  String? _direccion;
  int? _tipo;
  String? pathImage;

  @override
  void initState() {
    super.initState();
    initPlatformState();
    initSavetoPath();
    _getUserInfo();
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

  Future<void> initPlatformState() async {
    final isConnected = await bluetooth.isConnected;
    List<BluetoothDevice> devices = [];
    try {
      devices = await bluetooth.getBondedDevices();
    } on PlatformException {
      devices = [];
    }

    bluetooth.onStateChanged().listen((state) {
      if (!mounted) return;
      switch (state) {
        case BlueThermalPrinter.CONNECTED:
          setState(() {
            _connected = true;
          });
          break;
        case BlueThermalPrinter.DISCONNECTED:
          setState(() {
            _connected = false;
          });
          break;
        default:
          break;
      }
    });

    if (!mounted) return;
    setState(() {
      _devices = devices;
      _connected = isConnected == true;
    });
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
      _dispositivo = user['dispositivo']?.toString();
      _direccion =
          (user['address'] ?? user['direccion'])?.toString();
      final tipoValue = user['tipo'];
      _tipo = tipoValue is int ? tipoValue : int.tryParse('$tipoValue');
    });
  }

  Future<void> _guardarImpresora() async {
    if (_dispositivo == null || _direccion == null || _tipo == null) {
      return;
    }
    final data = {
      'dispositivo': _dispositivo,
      'tipo': _tipo,
      'address': _direccion,
      'direccion': _direccion,
    };

    final res = await CallApi().postData(data, 'guardarImpresora');
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (body['success'] == true) {
      final localStorage = await SharedPreferences.getInstance();
      await localStorage.setString('user', jsonEncode(body['user']));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccion'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                const SizedBox(width: 4),
                const Text(
                  'Dis:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: !_connected
                      ? DropdownButton<BluetoothDevice?>(
                          isExpanded: true,
                          items: _getDeviceItems(),
                          hint: const Text('Selecciona un dispositivo'),
                          value: _device,
                          onChanged: (value) {
                            setState(() {
                              _device = value;
                              _dispositivo = value?.name;
                              _direccion = value?.address;
                              _tipo = value?.type;
                            });
                          },
                        )
                      : Center(
                          child: Text(
                            _dispositivo ?? 'Sin dispositivo',
                            style: const TextStyle(fontSize: 18.0),
                          ),
                        ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.brown),
                  onPressed: initPlatformState,
                  child: const Text('Actualizar', style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _connected ? Colors.red : Colors.green,
                  ),
                  onPressed: _connected ? _disconnect : _connect,
                  child: Text(
                    _connected ? 'Desconectar' : 'Conectar',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0.0, 35.0, 0.0, 0.0),
              child: ListTile(
                title: const Text(
                  'Imprimir Prueba',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                ),
                trailing: Icon(
                  Icons.print,
                  color: Colors.grey.shade400,
                ),
                onTap: () {
                  if (_connected) {
                    final direccion =
                        userData?['direccion']?.toString() ??
                        userData?['address']?.toString() ??
                        '';
                    final imagePath = pathImage;
                    if (imagePath != null) {
                      testPrint.sample(imagePath, direccion);
                    }
                  } else {
                    _showMessage('Ningún dispositivo conectado');
                  }
                },
              ),
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

  List<DropdownMenuItem<BluetoothDevice?>> _getDeviceItems() {
    if (_devices.isEmpty) {
      return const [
        DropdownMenuItem<BluetoothDevice?>(
          value: null,
          child: Text('Ningún dispositivo encontrado'),
        ),
      ];
    }
    return _devices
        .map(
          (device) => DropdownMenuItem<BluetoothDevice?>(
            value: device,
            child: Text(device.name ?? 'Dispositivo sin nombre'),
          ),
        )
        .toList();
  }

  Future<void> _connect() async {
    final device = _device;
    if (device == null) {
      _showMessage('Ningún dispositivo seleccionado');
      return;
    }

    final isConnected = await bluetooth.isConnected;
    if (isConnected == true) {
      setState(() {
        _connected = true;
      });
      return;
    }

    try {
      await bluetooth.connect(device);
      if (mounted) {
        setState(() {
          _connected = true;
          _dispositivo = device.name;
          _direccion = device.address;
          _tipo = device.type;
        });
      }
      await _guardarImpresora();
    } catch (error) {
      if (mounted) {
        setState(() {
          _connected = false;
        });
      }
      _showMessage('No se pudo conectar: $error');
    }
  }

  Future<void> _disconnect() async {
    await bluetooth.disconnect();
    if (mounted) {
      setState(() {
        _connected = false;
      });
    }
  }

  Future<void> writeToFile(ByteData data, String path) {
    final buffer = data.buffer;
    return File(path).writeAsBytes(
      buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
  }
}
