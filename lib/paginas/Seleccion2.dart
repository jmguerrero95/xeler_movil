import 'dart:async';
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
  bool _bluetoothEnabled = false;
  bool _loadingDevices = false;
  bool _permissionsGranted = true;
  bool _enablingBluetooth = false;
  StreamSubscription<int>? _stateSubscription;
  StreamSubscription<bool>? _adapterSubscription;
  Map<String, dynamic>? userData;
  String? _dispositivo;
  String? _direccion;
  int? _tipo;
  String? pathImage;

  @override
  void initState() {
    super.initState();
    _stateSubscription = bluetooth.onStateChanged().listen((state) {
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
    _adapterSubscription =
        bluetooth.onBluetoothEnabledChanged().listen((enabled) {
      if (!mounted) return;
      setState(() {
        _bluetoothEnabled = enabled;
        if (!enabled) {
          _connected = false;
          _devices = [];
        }
      });
      if (enabled && !_loadingDevices) {
        unawaited(initPlatformState());
      }
    });
    initPlatformState(notifyIfDenied: true);
    initSavetoPath();
    _getUserInfo();
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    _adapterSubscription?.cancel();
    super.dispose();
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

  Future<void> initPlatformState({bool notifyIfDenied = false}) async {
    if (!mounted) return;

    setState(() {
      _loadingDevices = true;
    });

    final hasPermissions = await _ensurePermissions(showWarning: notifyIfDenied);
    if (!hasPermissions) {
      if (!mounted) return;
      setState(() {
        _devices = [];
        _connected = false;
        _bluetoothEnabled = false;
        _loadingDevices = false;
        _permissionsGranted = false;
      });
      return;
    }

    final enabled = await bluetooth.isBluetoothEnabled;
    List<BluetoothDevice> devices = [];
    bool isConnected = false;
    if (enabled) {
      try {
        devices = await bluetooth.getBondedDevices();
      } on PlatformException {
        devices = [];
      }
      isConnected = await bluetooth.isConnected == true;
    }

    BluetoothDevice? selectedDevice = _device;
    if (_direccion != null) {
      for (final candidate in devices) {
        if (candidate.address == _direccion) {
          selectedDevice = candidate;
          break;
        }
      }
    }

    if (!mounted) return;
    setState(() {
      _devices = devices;
      _connected = isConnected;
      _bluetoothEnabled = enabled;
      _device = selectedDevice;
      _loadingDevices = false;
      _permissionsGranted = true;
    });

    if (!enabled && notifyIfDenied && mounted) {
      _showMessage('Activa el Bluetooth del dispositivo para continuar');
    }
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
            if (_loadingDevices) const LinearProgressIndicator(),
            if (!_permissionsGranted)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, color: Colors.redAccent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        bluetooth.permissionsPermanentlyDenied
                            ? 'Debes habilitar manualmente los permisos de Bluetooth para poder buscar impresoras.'
                            : 'Otorga los permisos de Bluetooth para detectar impresoras cercanas.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    if (bluetooth.permissionsPermanentlyDenied)
                      TextButton(
                        onPressed: bluetooth.openSystemSettings,
                        child: const Text('Abrir ajustes'),
                      )
                    else
                      TextButton(
                        onPressed: () => initPlatformState(notifyIfDenied: true),
                        child: const Text('Solicitar permisos'),
                      ),
                  ],
                ),
              )
            else if (!_bluetoothEnabled)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.redAccent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Bluetooth está desactivado. Enciéndelo para buscar impresoras cercanas.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: _enablingBluetooth
                          ? null
                          : () async {
                              await _requestEnableBluetooth();
                            },
                      child: _enablingBluetooth
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Encender'),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.brown),
                  onPressed: () => initPlatformState(notifyIfDenied: true),
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
                onTap: () async {
                  if (_connected) {
                    final direccion =
                        userData?['direccion']?.toString() ??
                        userData?['address']?.toString() ??
                        '';
                    final imagePath = pathImage;
                    if (imagePath != null) {
                      await testPrint.sample(imagePath, direccion);
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

  Future<bool> _ensurePermissions({bool showWarning = false}) async {
    final granted = await bluetooth.ensurePermissions();
    if (mounted) {
      setState(() {
        _permissionsGranted = granted;
        if (!granted) {
          _bluetoothEnabled = false;
          _connected = false;
          _devices = [];
          _device = null;
          _dispositivo = null;
          _direccion = null;
          _tipo = null;
        }
      });
    }
    if (!granted && mounted && showWarning) {
      if (bluetooth.permissionsPermanentlyDenied) {
        _showMessage(
          'Debes habilitar los permisos de Bluetooth manualmente desde ajustes.',
          action: SnackBarAction(
            label: 'Abrir',
            onPressed: () {
              bluetooth.openSystemSettings();
            },
          ),
        );
      } else {
        _showMessage('Se requieren permisos de Bluetooth para continuar.');
      }
    }
    return granted;
  }

  Future<void> _requestEnableBluetooth() async {
    if (_enablingBluetooth) {
      return;
    }

    if (!await _ensurePermissions(showWarning: true)) {
      return;
    }

    if (mounted) {
      setState(() {
        _enablingBluetooth = true;
      });
    }

    bool enabled = false;
    try {
      enabled = await bluetooth.requestEnableBluetooth();
    } catch (error) {
      enabled = false;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _enablingBluetooth = false;
    });

    if (!enabled) {
      _showMessage('No se pudo activar el Bluetooth. Verifica los permisos del sistema.');
    }

    await initPlatformState(notifyIfDenied: true);
  }

  Future<void> _connect() async {
    final device = _device;
    if (device == null) {
      _showMessage('Ningún dispositivo seleccionado');
      return;
    }

    if (!await _ensurePermissions(showWarning: true)) {
      return;
    }

    final enabled = await bluetooth.isBluetoothEnabled;
    if (!enabled) {
      _showMessage('Activa el Bluetooth del dispositivo para conectar la impresora.');
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

  void _showMessage(String message, {SnackBarAction? action}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          action: action,
        ),
      );
  }
}
