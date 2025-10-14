library blue_thermal_printer;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:charset_converter/charset_converter.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:image/image.dart' as img;
import 'package:meta/meta.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

/// Compatibility wrapper mimicking the legacy `blue_thermal_printer` API while
/// relying on maintained, null-safe packages underneath.
class BlueThermalPrinter {
  BlueThermalPrinter._internal() {
    _startStateMonitor();
  }

  static final BlueThermalPrinter instance = BlueThermalPrinter._internal();
  static bool _stateMonitoringEnabled = true;

  @visibleForTesting
  static void configure({required bool stateMonitoringEnabled}) {
    _stateMonitoringEnabled = stateMonitoringEnabled;
    if (!_stateMonitoringEnabled) {
      instance._stopStateMonitor();
    } else {
      instance._startStateMonitor();
    }
  }

  static const int CONNECTED = 1;
  static const int DISCONNECTED = 0;

  final StreamController<int> _stateController =
      StreamController<int>.broadcast();

  Timer? _stateTimer;
  bool? _lastConnected;

  CapabilityProfile? _profile;
  bool _permissionsPermanentlyDenied = false;

  /// Paper size used for ESC/POS command generation.
  final PaperSize _paperSize = PaperSize.mm58;

  Stream<int> onStateChanged() => _stateController.stream;

  bool get permissionsPermanentlyDenied => _permissionsPermanentlyDenied;

  Future<bool?> get isConnected async {
    try {
      return await PrintBluetoothThermal.connectionStatus;
    } catch (_) {
      return false;
    }
  }

  Future<bool> openSystemSettings() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return false;
    }
    try {
      return await openAppSettings();
    } catch (_) {
      return false;
    }
  }

  Future<bool> get isBluetoothEnabled async {
    try {
      return await PrintBluetoothThermal.bluetoothEnabled;
    } catch (_) {
      return false;
    }
  }

  Future<bool> ensurePermissions() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return true;
    }

    _permissionsPermanentlyDenied = false;

    if (Platform.isAndroid) {
      final Map<Permission, PermissionStatus> statuses = await <Permission>[
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,
      ].request();

      for (final entry in statuses.entries) {
        final permission = entry.key;
        final status = entry.value;
        if (status.isPermanentlyDenied &&
            permission != Permission.locationWhenInUse) {
          _permissionsPermanentlyDenied = true;
        }
      }
    } else if (Platform.isIOS) {
      final status = await Permission.bluetooth.request();
      if (status.isPermanentlyDenied) {
        _permissionsPermanentlyDenied = true;
      }
      if (!status.isGranted && !status.isLimited) {
        return false;
      }
    }

    try {
      return await PrintBluetoothThermal.isPermissionBluetoothGranted;
    } catch (_) {
      return false;
    }
  }

  Future<List<BluetoothDevice>> getBondedDevices() async {
    final hasPermissions = await ensurePermissions();
    if (!hasPermissions) {
      return <BluetoothDevice>[];
    }

    final enabled = await isBluetoothEnabled;
    if (!enabled) {
      return <BluetoothDevice>[];
    }

    try {
      final results = await PrintBluetoothThermal.pairedBluetooths;
      return results
          .map((dynamic item) => BluetoothDevice.fromDynamic(item))
          .where(
              (device) => device.address != null && device.address!.isNotEmpty)
          .toList();
    } catch (_) {
      return <BluetoothDevice>[];
    }
  }

  Future<void> connect(BluetoothDevice device) async {
    final hasPermissions = await ensurePermissions();
    if (!hasPermissions) {
      throw StateError('Permisos de Bluetooth denegados');
    }

    final enabled = await isBluetoothEnabled;
    if (!enabled) {
      throw StateError('Bluetooth desactivado');
    }

    final address = device.address;
    if (address == null || address.isEmpty) {
      throw ArgumentError('El dispositivo no tiene dirección Bluetooth');
    }
    final result = await PrintBluetoothThermal.connect(
      macPrinterAddress: address,
    );
    if (result != true) {
      throw Exception('No se pudo establecer la conexión');
    }
    _stateController.add(CONNECTED);
  }

  Future<void> disconnect() async {
    try {
      final dynamic disconnectMember = PrintBluetoothThermal.disconnect;
      if (disconnectMember is Future) {
        await disconnectMember;
      } else if (disconnectMember is Future<bool> Function()) {
        await disconnectMember();
      }
    } finally {
      _stateController.add(DISCONNECTED);
    }
  }

  Future<void> printNewLine() async {
    final generator = await _getGenerator();
    await _send(generator.emptyLines(1));
  }

  Future<void> printCustom(
    String text,
    int size,
    int align, {
    String? charset,
  }) async {
    final styles = PosStyles(
      align: _mapAlign(align),
      bold: size >= 2,
      height: _mapTextSize(size),
      width: _mapTextSize(size),
    );

    final generator = await _getGenerator();
    List<int> bytes;
    if (charset != null) {
      bytes = generator.textEncoded(
        await _encode(text, charset),
        styles: styles,
        linesAfter: 0,
      );
    } else {
      bytes = generator.text(
        text,
        styles: styles,
        linesAfter: 0,
      );
    }
    await _send(bytes);
  }

  Future<void> printImage(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw ArgumentError('Imagen no encontrada en $path');
    }
    final data = await file.readAsBytes();
    final decoded = img.decodeImage(data);
    if (decoded == null) {
      throw Exception('No fue posible decodificar la imagen proporcionada');
    }
    final image =
        decoded.width > 384 ? img.copyResize(decoded, width: 384) : decoded;
    final generator = await _getGenerator();
    final bytes = generator.imageRaster(
      image,
      align: PosAlign.center,
    );
    await _send(bytes);
  }

  Future<void> printBytes(Uint8List bytes) async {
    if (bytes.isEmpty) return;
    await _send(bytes.toList());
  }

  void _startStateMonitor() {
    if (!_stateMonitoringEnabled) {
      _stopStateMonitor();
      return;
    }
    _stateTimer ??= Timer.periodic(const Duration(seconds: 2), (_) async {
      final connected = await isConnected ?? false;
      if (_lastConnected != connected) {
        _lastConnected = connected;
        _stateController.add(connected ? CONNECTED : DISCONNECTED);
      }
    });
  }

  void _stopStateMonitor() {
    _stateTimer?.cancel();
    _stateTimer = null;
  }

  Future<void> dispose() async {
    _stopStateMonitor();
    await _stateController.close();
  }

  Future<CapabilityProfile> _loadProfile() async {
    if (_profile != null) {
      return _profile!;
    }
    try {
      _profile = await CapabilityProfile.load();
    } catch (error) {
      // The upstream API does not expose a public constructor, so the only
      // recovery strategy is to retry the default profile load explicitly.
      // If this still fails we surface the original exception to the caller
      // so the UI can react accordingly.
      try {
        _profile = await CapabilityProfile.load(name: 'default');
      } catch (_) {
        throw Exception('No se pudo cargar el perfil de la impresora: $error');
      }
    }
    return _profile!;
  }

  Future<Generator> _getGenerator() async {
    final profile = await _loadProfile();
    return Generator(_paperSize, profile);
  }

  Future<void> _send(List<int> bytes) async {
    if (bytes.isEmpty) {
      return;
    }
    final connected = await isConnected;
    if (connected != true) {
      throw StateError('La impresora no está conectada');
    }
    await PrintBluetoothThermal.writeBytes(Uint8List.fromList(bytes));
  }

  PosAlign _mapAlign(int align) {
    switch (align) {
      case 1:
        return PosAlign.center;
      case 2:
        return PosAlign.right;
      default:
        return PosAlign.left;
    }
  }

  PosTextSize _mapTextSize(int size) {
    return size >= 2 ? PosTextSize.size2 : PosTextSize.size1;
  }

  Future<Uint8List> _encode(String text, String charset) async {
    try {
      final encoded = await CharsetConverter.encode(charset, text);
      return Uint8List.fromList(encoded);
    } catch (_) {
      return Uint8List.fromList(const Utf8Encoder().convert(text));
    }
  }
}

/// Minimal Bluetooth device model compatible with the legacy API.
class BluetoothDevice {
  BluetoothDevice({this.name, this.address, this.type});

  factory BluetoothDevice.fromDynamic(dynamic value) {
    if (value is BluetoothDevice) {
      return value;
    }

    if (value is Map) {
      return BluetoothDevice(
        name: value['name']?.toString(),
        address: _readAddressFromMap(value),
        type: _parseType(value['type']),
      );
    }

    String? name;
    String? address;
    int? type;

    try {
      final dynamic dynamicValue = value;
      final dynamic dynamicName = dynamicValue.name;
      if (dynamicName is String) {
        name = dynamicName;
      }
    } catch (_) {}

    try {
      final dynamic dynamicValue = value;
      final dynamic dynamicAddress = dynamicValue.address ??
          dynamicValue.macAddress ??
          dynamicValue.macAdress;
      if (dynamicAddress is String) {
        address = dynamicAddress;
      }
    } catch (_) {}

    try {
      final dynamic dynamicValue = value;
      final dynamic dynamicType = dynamicValue.type;
      type = _parseType(dynamicType);
    } catch (_) {}

    return BluetoothDevice(
      name: name,
      address: address,
      type: type,
    );
  }

  factory BluetoothDevice.fromMap(Map<String, dynamic> map) {
    return BluetoothDevice(
      name: map['name']?.toString(),
      address: _readAddressFromMap(map),
      type: _parseType(map['type']),
    );
  }

  final String? name;
  final String? address;
  final int? type;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'name': name,
        'address': address,
        'type': type,
      };

  static int? _parseType(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    return int.tryParse('$value');
  }

  static String? _readAddressFromMap(Map<dynamic, dynamic> map) {
    final address = map['address'] ??
        map['macAddress'] ??
        map['macAdress'] ??
        map['mac'] ??
        map['mac_address'];
    return address?.toString();
  }
}
