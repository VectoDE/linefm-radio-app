import 'dart:ui' show Color;

class Station {
  const Station({
    required this.id,
    required this.slug,
    required this.displayName,
    required this.color,
    required this.logoAsset,
    required this.logoUrl,
    required this.fallbackStreamUrl,
  });

  final String id;
  final String slug;
  final String displayName;
  final Color color;
  final String logoAsset;
  final String logoUrl;
  final String fallbackStreamUrl;

  @override
  bool operator ==(Object other) =>
      other is Station && other.id == id && other.slug == slug;

  @override
  int get hashCode => Object.hash(id, slug);
}
