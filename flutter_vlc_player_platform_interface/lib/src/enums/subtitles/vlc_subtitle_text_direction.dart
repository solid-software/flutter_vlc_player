enum VlcSubtitleTextDirection { ltr, rtl, auto }

extension VlcSubtitleTextDirectionExtensionMap on VlcSubtitleTextDirection {
  static const valueMap = {
    VlcSubtitleTextDirection.ltr: 0,
    VlcSubtitleTextDirection.rtl: 1,
    VlcSubtitleTextDirection.auto: 2,
  };
  int? get value => valueMap[this];
}
