import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../config/ble_config.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// InsoleData Model
// ═══════════════════════════════════════════════════════════════════════════════

class InsoleData {
  final double heel, ball, arch, bigToe, secondToe;
  final bool   pressureAlert;
  final int    pressureLevel;
  final String pressureZone;
  final int    sustainedHeel, sustainedBall, sustainedArch,
               sustainedBigToe, sustainedSecondToe;
  final double tempC, tempDelta, tempThresh;
  final bool   tempAlert;
  final double accelG, heading;
  final int    steps;
  final String direction;
  final double gaitSymmetry;
  final bool   gaitAlert, fallDetected;

  const InsoleData({
    required this.heel, required this.ball, required this.arch,
    required this.bigToe, required this.secondToe,
    required this.pressureAlert, required this.pressureLevel,
    required this.pressureZone,
    required this.sustainedHeel, required this.sustainedBall,
    required this.sustainedArch, required this.sustainedBigToe,
    required this.sustainedSecondToe,
    required this.tempC, required this.tempDelta, required this.tempThresh,
    required this.tempAlert,
    required this.accelG, required this.heading, required this.steps,
    required this.direction, required this.gaitSymmetry,
    required this.gaitAlert, required this.fallDetected,
  });

  factory InsoleData.fromJson(Map<String, dynamic> j) {
    final p   = j['pressure']      as Map<String, dynamic>? ?? {};
    final sus = j['sustained_min'] as Map<String, dynamic>? ?? {};
    return InsoleData(
      heel:       (p['heel']       ?? 0).toDouble(),
      ball:       (p['ball']       ?? 0).toDouble(),
      arch:       (p['arch']       ?? 0).toDouble(),
      bigToe:     (p['big_toe']    ?? 0).toDouble(),
      secondToe:  (p['second_toe'] ?? 0).toDouble(),
      pressureAlert: j['pressure_alert'] == true,
      pressureLevel: (j['pressure_level'] ?? 0) as int,
      pressureZone:  j['pressure_zone']  ?? '',
      sustainedHeel:      (sus['heel']       ?? 0) as int,
      sustainedBall:      (sus['ball']       ?? 0) as int,
      sustainedArch:      (sus['arch']       ?? 0) as int,
      sustainedBigToe:    (sus['big_toe']    ?? 0) as int,
      sustainedSecondToe: (sus['second_toe'] ?? 0) as int,
      tempC:      (j['temp_c']      ?? 0).toDouble(),
      tempDelta:  (j['temp_delta']  ?? 0).toDouble(),
      tempAlert:  j['temp_alert']   == true,
      tempThresh: (j['temp_thresh'] ?? 40.0).toDouble(),
      accelG:    (j['accel_g']       ?? 0).toDouble(),
      steps:     (j['steps']         ?? 0) as int,
      heading:   (j['heading']       ?? 0).toDouble(),
      direction: j['direction']      ?? '--',
      gaitSymmetry: (j['gait_symmetry'] ?? 0).toDouble(),
      gaitAlert:    j['gait_alert']     == true,
      fallDetected: j['fall']           == true,
    );
  }

  bool   get isSafe             => !pressureAlert && !tempAlert && !fallDetected;
  String get tempString         => '${tempC.toStringAsFixed(1)}°C';
  String get stepsString        => '$steps';
  double get maxPressure        => [heel, ball, arch, bigToe, secondToe].reduce((a, b) => a > b ? a : b);
  String get pressureStatusText => maxPressure >= 85 ? 'High' : maxPressure >= 50 ? 'Normal' : 'Low';

  String get statusText {
    if (fallDetected)        return 'Fall Detected!';
    if (pressureLevel == 3)  return 'Critical Pressure';
    if (pressureLevel == 2)  return 'Urgent Pressure';
    if (pressureLevel == 1)  return 'Pressure Warning';
    if (tempAlert)           return 'High Temperature';
    return 'Safe';
  }

  String get statusSub {
    if (fallDetected)  return 'Please check the patient immediately';
    if (pressureAlert) return 'Zone: $pressureZone — ${sustainedHeel}min sustained';
    if (tempAlert)     return 'Temp: ${tempC.toStringAsFixed(1)}°C (Δ${tempDelta.toStringAsFixed(1)}°C)';
    return 'Your foot condition is stable';
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// BLE Service — flutter_blue_plus + MTU + packet reassembly
// ═══════════════════════════════════════════════════════════════════════════════

class BleService {
  BluetoothDevice?         _device;
  BluetoothCharacteristic? _txChar;
  StreamSubscription?      _notifySubscription;

  // Buffer for packet reassembly
  final StringBuffer _buffer = StringBuffer();

  final _dataController   = StreamController<InsoleData>.broadcast();
  final _statusController = StreamController<String>.broadcast();

  Stream<InsoleData> get dataStream   => _dataController.stream;
  Stream<String>     get statusStream => _statusController.stream;
  bool get isConnected => _device != null;

  // ── Handle incoming BLE data with reassembly ──────────────────────────────
  void _handleData(List<int> data) {
    if (data.isEmpty) return;

    final chunk = utf8.decode(data, allowMalformed: true);
    _buffer.write(chunk);

    final buffered = _buffer.toString();

    // Find complete JSON object
    final start = buffered.indexOf('{');
    if (start == -1) { _buffer.clear(); return; }

    int depth = 0;
    int end   = -1;

    for (int i = start; i < buffered.length; i++) {
      if (buffered[i] == '{') depth++;
      if (buffered[i] == '}') depth--;
      if (depth == 0 && i > start) { end = i; break; }
    }

    if (end != -1) {
      final jsonStr = buffered.substring(start, end + 1);
      _buffer.clear();

      // Keep leftover data after JSON
      if (end + 1 < buffered.length) {
        _buffer.write(buffered.substring(end + 1));
      }

      try {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        _dataController.add(InsoleData.fromJson(map));
      } catch (_) {}
    }
  }

  // ── Connect ───────────────────────────────────────────────────────────────
  Future<bool> connect() async {
    try {
      _buffer.clear();
      _statusController.add("Connecting...");

      // Scan first to find device, then connect
      BluetoothDevice? found;

      final scanSub = FlutterBluePlus.onScanResults.listen((results) {
        for (final r in results) {
          if (r.device.remoteId.str == BleConfig.deviceMacAddress ||
              r.device.platformName == BleConfig.deviceName ||
              r.advertisementData.advName == BleConfig.deviceName) {
            found = r.device;
          }
        }
      });

      await FlutterBluePlus.startScan(
        timeout: Duration(seconds: BleConfig.scanTimeout),
      );
      await FlutterBluePlus.isScanning.where((v) => !v).first;
      await scanSub.cancel();

      if (found != null) {
        _device = found;
      } else {
        // Fallback: connect by MAC directly
        _device = BluetoothDevice.fromId(BleConfig.deviceMacAddress);
      }

      // Connect with MTU request
      await _device!.connect(
        autoConnect: false,
        mtu:         512,
      );

      // Listen for disconnection
      _device!.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _statusController.add("Disconnected");
          _device = null;
          _txChar = null;
          _buffer.clear();
        }
      });

      _statusController.add("Discovering services...");

      // Wait for connection to stabilize
      await Future.delayed(const Duration(milliseconds: 500));

      // Discover services
      final services = await _device!.discoverServices();

      for (final svc in services) {
        if (svc.uuid.str128.toUpperCase() ==
            BleConfig.serviceUuid.toUpperCase()) {
          for (final c in svc.characteristics) {
            if (c.uuid.str128.toUpperCase() ==
                BleConfig.characteristicUuid.toUpperCase()) {
              _txChar = c;
            }
          }
        }
      }

      if (_txChar == null) {
        _statusController.add("Characteristic not found");
        return false;
      }

      // Enable notifications
      await _txChar!.setNotifyValue(true);

      // Listen with reassembly buffer
      _notifySubscription = _txChar!.lastValueStream.listen(_handleData);

      _statusController.add("Connected ✅");
      return true;

    } catch (e) {
      _statusController.add("Error: $e");
      _device = null;
      return false;
    }
  }

  Future<void> sendCommand(String cmd) async {
    if (_device == null) return;
    try {
      final services = await _device!.discoverServices();
      for (final svc in services) {
        if (svc.uuid.str128.toUpperCase() ==
            BleConfig.serviceUuid.toUpperCase()) {
          for (final c in svc.characteristics) {
            if (c.uuid.str128.toUpperCase() ==
                BleConfig.rxUuid.toUpperCase()) {
              await c.write(utf8.encode(cmd));
              return;
            }
          }
        }
      }
    } catch (_) {}
  }

  Future<void> disconnect() async {
    await _notifySubscription?.cancel();
    await _device?.disconnect();
    _device = null;
    _txChar = null;
    _buffer.clear();
    _statusController.add("Disconnected");
  }

  void dispose() {
    _notifySubscription?.cancel();
    _dataController.close();
    _statusController.close();
    _device?.disconnect();
  }
}