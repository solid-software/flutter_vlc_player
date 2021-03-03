enum VlcSubtitleThickness {
  None,
  Thin,
  Normal,
  Thick,
}

extension VlcSubtitleThicknessExtensionMap on VlcSubtitleThickness {
  static const valueMap = {
    VlcSubtitleThickness.None: 0,
    VlcSubtitleThickness.Thin: 2,
    VlcSubtitleThickness.Normal: 4,
    VlcSubtitleThickness.Thick: 6,
  };
  int get value => valueMap[this];
}