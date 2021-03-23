class VlcSubtitleThickness {
  static const none = VlcSubtitleThickness(0);
  static const thin = VlcSubtitleThickness(2);
  static const normal = VlcSubtitleThickness(4);
  static const thick = VlcSubtitleThickness(6);

  final int value;
  const VlcSubtitleThickness(this.value);
}
