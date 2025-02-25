// ignore_for_file: constant_identifier_names

extension ByteSize on int {
  static const int _KB = 1024;
  static const int _MB = _KB * 1024;
  static const int _GB = _MB * 1024;
  static const int _TB = _GB * 1024;

  double toBits() => this * 8;
  double toBytes() => toDouble();
  double toKB() => this / _KB;
  double toMB() => this / _MB;
  double toGB() => this / _GB;
  double toTB() => this / _TB;

  /// Automatically selecting B, KB, MB, GB, or TB as appropriate.
  String getSize([int fractionDigits = 2]) {
    final units = ['B', 'KB', 'MB', 'GB', 'TB'];
    double value = toDouble();
    int unitIndex = 0;

    // Sequentially divide until the value is less than 1024 or we reach the largest unit.
    while (value >= _KB && unitIndex < units.length - 1) {
      value /= _KB;
      unitIndex++;
    }
    return '${value.toStringAsPrecision(fractionDigits)} ${units[unitIndex]}';
  }
}