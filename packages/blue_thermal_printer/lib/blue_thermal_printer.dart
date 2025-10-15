library blue_thermal_printer;

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:charset_converter/charset_converter.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/services.dart';
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
  static const MethodChannel _bluetoothStateChannel =
      MethodChannel('com.example.xeler_impresora/bluetooth');

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
  bool? _lastKnownBluetoothEnabled;

  CapabilityProfile? _profile;
  bool _permissionsPermanentlyDenied = false;
  int? _cachedAndroidVersion;

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
    bool? enabled;
    try {
      enabled = await PrintBluetoothThermal.bluetoothEnabled
          .timeout(const Duration(milliseconds: 500));
    } catch (_) {
      enabled = null;
    }

    if (enabled == null && Platform.isAndroid) {
      try {
        enabled = await _bluetoothStateChannel
            .invokeMethod<bool>('isBluetoothEnabled')
            .timeout(const Duration(milliseconds: 500));
      } catch (_) {
        enabled = null;
      }
    }

    _lastKnownBluetoothEnabled = enabled ?? _lastKnownBluetoothEnabled;
    return _lastKnownBluetoothEnabled ?? false;
  }

  Future<bool> ensurePermissions() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return true;
    }

    _permissionsPermanentlyDenied = false;

    bool requiredPermissionsGranted = true;

    if (Platform.isAndroid) {
      final int androidVersion = await _resolveAndroidVersion() ?? 11;
      final bool enforceLegacyPermissions = androidVersion < 12;

      final List<Permission> permissions = <Permission>[
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        if (androidVersion >= 12) Permission.bluetoothAdvertise,
        Permission.locationWhenInUse,
        if (enforceLegacyPermissions) Permission.bluetooth,
      ];

      final Map<Permission, PermissionStatus> statuses =
          <Permission, PermissionStatus>{};
      for (final Permission permission in permissions) {
        statuses[permission] = await permission.request();
      }

      for (final Permission permission in permissions) {
        final PermissionStatus status =
            statuses[permission] ?? await permission.status;

        final bool isGranted = status.isGranted || status.isLimited;
        final bool isLocationPermission =
            permission == Permission.locationWhenInUse;
        final bool isLegacyBluetoothPermission =
            permission == Permission.bluetooth;
        final bool permissionIsMandatory =
            isLocationPermission || isLegacyBluetoothPermission
                ? enforceLegacyPermissions
                : true;

        if (status.isPermanentlyDenied && permissionIsMandatory) {
          _permissionsPermanentlyDenied = true;
        }

        if (isGranted || !permissionIsMandatory) {
          continue;
        }

        requiredPermissionsGranted = false;
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
      final bool pluginGranted = await PrintBluetoothThermal
          .isPermissionBluetoothGranted
          .timeout(const Duration(milliseconds: 500));
      if (pluginGranted) {
        return true;
      }
    } catch (_) {
      // Ignored: the plugin is best-effort and may timeout when permissions
      // are unavailable. We fall back to the explicit permission handler
      // checks below.
    }
    return requiredPermissionsGranted;
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

    final List<BluetoothDevice> pluginDevices =
        await _getPluginBondedDevices();
    final List<BluetoothDevice> nativeDevices =
        await _getNativeBondedDevices();

    final LinkedHashMap<String, BluetoothDevice> devicesByAddress =
        LinkedHashMap<String, BluetoothDevice>();
    final List<BluetoothDevice> devicesWithoutAddress =
        <BluetoothDevice>[];

    void addDevice(BluetoothDevice device) {
      final String? address = device.address;
      if (address == null || address.isEmpty) {
        devicesWithoutAddress.add(device);
        return;
      }

      final BluetoothDevice? existing = devicesByAddress[address];
      if (existing == null) {
        devicesByAddress[address] = device;
        return;
      }

      final bool hasExistingName =
          (existing.name != null && existing.name!.isNotEmpty);
      final bool hasNewName = (device.name != null && device.name!.isNotEmpty);

      if (!hasExistingName && hasNewName) {
        devicesByAddress[address] = device;
      }
    }

    for (final BluetoothDevice device in pluginDevices) {
      addDevice(device);
    }
    for (final BluetoothDevice device in nativeDevices) {
      addDevice(device);
    }

    return <BluetoothDevice>[
      ...devicesByAddress.values,
      ...devicesWithoutAddress,
    ];
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

  Future<int?> _resolveAndroidVersion() async {
    if (!Platform.isAndroid) {
      return null;
    }
    if (_cachedAndroidVersion != null) {
      return _cachedAndroidVersion;
    }

    final List<String?> candidates = <String?>[];
    try {
      candidates.add(await PrintBluetoothThermal.platformVersion);
    } catch (_) {
      // Ignored: the version lookup is best-effort.
    }
    candidates
      ..add(Platform.operatingSystemVersion)
      ..add(Platform.version);

    for (final String? candidate in candidates) {
      final int? parsed = _parseAndroidVersion(candidate);
      if (parsed != null) {
        _cachedAndroidVersion = parsed;
        return parsed;
      }
    }

    return null;
  }

  int? _parseAndroidVersion(String? source) {
    if (source == null || source.isEmpty) {
      return null;
    }

    final RegExpMatch? androidMatch =
        RegExp(r'Android\s*(\d+)(?:\.\d+)?').firstMatch(source);
    if (androidMatch != null) {
      return int.tryParse(androidMatch.group(1)!);
    }

    final RegExpMatch? apiMatch = RegExp(r'API\s*(\d+)').firstMatch(source);
    if (apiMatch != null) {
      final int? api = int.tryParse(apiMatch.group(1)!);
      if (api != null) {
        return _androidVersionFromApi(api);
      }
    }

    return null;
  }

  int? _androidVersionFromApi(int api) {
    if (api >= 35) return 15;
    if (api >= 34) return 14;
    if (api >= 33) return 13;
    if (api >= 32) return 12;
    if (api >= 31) return 12;
    if (api >= 30) return 11;
    if (api >= 29) return 10;
    if (api >= 28) return 9;
    if (api >= 27) return 8;
    if (api >= 26) return 8;
    if (api >= 25) return 7;
    if (api >= 24) return 7;
    if (api >= 23) return 6;
    if (api >= 22) return 5;
    if (api >= 21) return 5;
    return null;
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

  Future<List<BluetoothDevice>> _getPluginBondedDevices() async {
    try {
      final results = await PrintBluetoothThermal.pairedBluetooths
          .timeout(const Duration(seconds: 2));
      return results
          .map((dynamic item) => BluetoothDevice.fromDynamic(item))
          .toList();
    } on TimeoutException {
      return <BluetoothDevice>[];
    } catch (_) {
      return <BluetoothDevice>[];
    }
  }

  Future<List<BluetoothDevice>> _getNativeBondedDevices() async {
    if (!Platform.isAndroid) {
      return <BluetoothDevice>[];
    }

    try {
      final List<Map<dynamic, dynamic>>? rawDevices =
          await _bluetoothStateChannel
              .invokeListMethod<Map<dynamic, dynamic>>('getBondedDevices')
              .timeout(const Duration(milliseconds: 500));

      if (rawDevices == null) {
        return <BluetoothDevice>[];
      }

      return rawDevices
          .map(
            (Map<dynamic, dynamic> item) => BluetoothDevice.fromMap(
              item.map(
                (dynamic key, dynamic value) =>
                    MapEntry<String, dynamic>(key.toString(), value),
              ),
            ),
          )
          .toList();
    } on TimeoutException {
      return <BluetoothDevice>[];
    } catch (_) {
      return <BluetoothDevice>[];
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
