class IptvChannel {
  final String id;
  final String name;
  final String manifestUri;
  final Map<String, String> clearKeys;
  final String logoUrl;
  final String category;

  const IptvChannel({
    required this.id,
    required this.name,
    required this.manifestUri,
    required this.clearKeys,
    this.logoUrl = '',
    this.category = 'General',
  });
}

/// Static hardcoded channels
class IptvChannels {
  static const List<IptvChannel> all = [];
}