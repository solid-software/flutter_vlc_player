enum VlcSubtitleColor {
  black,
  gray,
  silver,
  white,
  maroon,
  red,
  fuchsia,
  yellow,
  olive,
  green,
  teal,
  lime,
  purple,
  navy,
  blue,
  aqua,
}

extension VlcSubtitleColorExtensionMap on VlcSubtitleColor {
  static const valueMap = {
    VlcSubtitleColor.black: 0,
    VlcSubtitleColor.gray: 8421504,
    VlcSubtitleColor.silver: 12632256,
    VlcSubtitleColor.white: 16777215,
    VlcSubtitleColor.maroon: 8388608,
    VlcSubtitleColor.red: 16711680,
    VlcSubtitleColor.fuchsia: 16711935,
    VlcSubtitleColor.yellow: 16776960,
    VlcSubtitleColor.olive: 8421376,
    VlcSubtitleColor.green: 32768,
    VlcSubtitleColor.teal: 32896,
    VlcSubtitleColor.lime: 65280,
    VlcSubtitleColor.purple: 8388736,
    VlcSubtitleColor.navy: 128,
    VlcSubtitleColor.blue: 255,
    VlcSubtitleColor.aqua: 65535,
  };
  int get value => valueMap[this];
}
