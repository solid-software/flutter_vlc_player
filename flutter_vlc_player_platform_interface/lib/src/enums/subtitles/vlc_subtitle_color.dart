enum VlcSubtitleColor {
  Black,
  Gray,
  Silver,
  White,
  Maroon,
  Red,
  Fuchsia,
  Yellow,
  Olive,
  Green,
  Teal,
  Lime,
  Purple,
  Navy,
  Blue,
  Aqua,
}

extension VlcSubtitleColorExtensionMap on VlcSubtitleColor {
  static const valueMap = {
    VlcSubtitleColor.Black: 0,
    VlcSubtitleColor.Gray: 8421504,
    VlcSubtitleColor.Silver: 12632256,
    VlcSubtitleColor.White: 16777215,
    VlcSubtitleColor.Maroon: 8388608,
    VlcSubtitleColor.Red: 16711680,
    VlcSubtitleColor.Fuchsia: 16711935,
    VlcSubtitleColor.Yellow: 16776960,
    VlcSubtitleColor.Olive: 8421376,
    VlcSubtitleColor.Green: 32768,
    VlcSubtitleColor.Teal: 32896,
    VlcSubtitleColor.Lime: 65280,
    VlcSubtitleColor.Purple: 8388736,
    VlcSubtitleColor.Navy: 128,
    VlcSubtitleColor.Blue: 255,
    VlcSubtitleColor.Aqua: 65535,
  };
  int get value => valueMap[this];
}
