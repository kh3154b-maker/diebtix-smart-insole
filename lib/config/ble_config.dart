class BleConfig {
  static const String deviceName         = "DiabeticInsole";
  static const String deviceMacAddress   = "C4:DD:57:92:6B:6A"; // ← MAC Address
  static const String serviceUuid        = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E";
  static const String characteristicUuid = "6E400003-B5A3-F393-E0A9-E50E24DCCA9E";
  static const String rxUuid             = "6E400002-B5A3-F393-E0A9-E50E24DCCA9E";
  static const int    scanTimeout        = 15;
  static const int    connectTimeout     = 15;
}