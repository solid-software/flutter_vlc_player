enum VlcSubtitleTextDirection {
  LTR,
  RTL,
  AUTO,
}

extension VlcSubtitleTextDirectionExtensionMap on VlcSubtitleTextDirection {
  static const valueMap = {
    VlcSubtitleTextDirection.LTR: 0,
    VlcSubtitleTextDirection.RTL: 1,
    VlcSubtitleTextDirection.AUTO: 2,
  };
  int get value => valueMap[this];
}
