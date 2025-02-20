class VlcSubtitleColor {
  static const _bitsInByte = 8;
  static const _redHexOffset = 2 * _bitsInByte;
  static const _greenHexOffset = _bitsInByte;
  static const black = VlcSubtitleColor(0);
  static const gray = VlcSubtitleColor(8421504);
  static const silver = VlcSubtitleColor(12632256);
  static const white = VlcSubtitleColor(16777215);
  static const maroon = VlcSubtitleColor(8388608);
  static const red = VlcSubtitleColor(16711680);
  static const fuchsia = VlcSubtitleColor(16711935);
  static const yellow = VlcSubtitleColor(16776960);
  static const olive = VlcSubtitleColor(8421376);
  static const green = VlcSubtitleColor(32768);
  static const teal = VlcSubtitleColor(32896);
  static const lime = VlcSubtitleColor(65280);
  static const purple = VlcSubtitleColor(8388736);
  static const navy = VlcSubtitleColor(128);
  static const blue = VlcSubtitleColor(255);
  static const aqua = VlcSubtitleColor(65535);

  final int value;
  const VlcSubtitleColor(this.value);
  const VlcSubtitleColor.rgb({int red = 0, int green = 0, int blue = 0})
    : value = (red << _redHexOffset) + (green << _greenHexOffset) + blue;
}
