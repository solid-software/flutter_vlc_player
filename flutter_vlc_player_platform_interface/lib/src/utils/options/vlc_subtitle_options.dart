import '../../enums/subtitles/vlc_subtitle_text_direction.dart';
import '../helpers/subtitles/vlc_subtitle_thickness.dart';
import '../helpers/subtitles/vlc_subtitle_color.dart';

class VlcSubtitleOptions {
  final List<String> options;

  VlcSubtitleOptions(this.options);

  /// Set subtitle font (must be accessible by vlc)
  static String font(String font) {
    return '--freetype-font=$font';
  }

  /// Set subtitle mono font (must be accessible by vlc)
  static String monofont(String monofont) {
    return '--freetype-monofont=$monofont';
  }

  /// Set subtitle font size
  static String fontSize(int size) {
    return '--freetype-fontsize=$size';
  }

  /// Set subtitle relative font size
  static String relativeFontSize(int size) {
    return '--freetype-rel-fontsize=$size';
  }

  /// Enable/Disable subtitle bold style
  static String boldStyle(bool enable) {
    return enable ? '--freetype-bold' : '--no-freetype-bold';
  }

  /// Set subtitle opacity [0 .. 255]
  static String opacity(int opacity) {
    return '--freetype-opacity=$opacity';
  }

  /// Set subtitle color
  static String color(VlcSubtitleColor color) {
    return '--freetype-color=${color.value}';
  }

  /// Set subtitle text direction {0 (Left to right), 1 (Right to left), 2 (Auto)}
  static String textDirection(VlcSubtitleTextDirection direction) {
    return '--freetype-text-direction=${direction.value}';
  }

  /// Set subtitle background opacity [0 .. 255]
  static String backgroundOpacity(int opacity) {
    return '--freetype-background-opacity=$opacity';
  }

  /// Set subtitle background color
  static String backgroundColor(VlcSubtitleColor color) {
    return '--freetype-background-color=${color.value}';
  }

  /// Set subtitle outline opacity [0 .. 255]
  static String outlineOpacity(int opacity) {
    return '--freetype-outline-opacity=$opacity';
  }

  /// Set subtitle outline color
  static String outlineColor(VlcSubtitleColor color) {
    return '--freetype-outline-color=${color.value}';
  }

  /// Set subtitle outline thickness {0 (None), 2 (Thin), 4 (Normal), 6 (Thick)}
  static String outlineThickness(VlcSubtitleThickness thickness) {
    return '--freetype-outline-thickness=${thickness.value}';
  }

  /// Set subtitle shadow opacity [0 .. 255]
  static String shadowOpacity(int opacity) {
    return '--freetype-shadow-opacity=$opacity';
  }

  /// Set subtitle shadow color
  static String shadowColor(VlcSubtitleColor color) {
    return '--freetype-shadow-color=${color.value}';
  }

  /// Set subtitle shadow angle [-360.000000 .. 360.000000]
  static String shadowAngle(double angle) {
    return '--freetype-shadow-angle=$angle';
  }

  /// Set subtitle shadow distance in [0.000000 .. 1.000000]
  static String shadowDistance(double distance) {
    return '--freetype-shadow-distance=$distance';
  }

  /// Enable/Disable subtitle yuvp renderer
  static String yuvpRenderer(bool enable) {
    return enable ? '--freetype-yuvp' : '--no-freetype-yuvp';
  }
}
