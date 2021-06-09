enum VideoType {
  asset,
  file,
  network,
  recorded,
}

class VideoData {
  final String name;
  final String path;
  final VideoType type;

  VideoData({
    this.name,
    this.path,
    this.type,
  });
}
