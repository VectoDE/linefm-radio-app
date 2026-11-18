import 'package:linefm_radio/domain/favorite.dart';

/// Plattformneutrale Favoriten-Logik (Stub, wird in P02 ausgebaut).
class FavoritesLogic {
  const FavoritesLogic._();

  static String keyFor({
    required String stationSlug,
    required String artist,
    required String title,
  }) => '$stationSlug:${artist.toLowerCase()}:${title.toLowerCase()}';

  /// Neue Favoriten vorn (wie unshift der Web-App).
  static List<Favorite> toggle(List<Favorite> list, Favorite item) {
    final exists = list.any((f) => f.key == item.key);
    if (exists) return remove(list, item.key);
    return <Favorite>[item, ...list];
  }

  static List<Favorite> remove(List<Favorite> list, String key) =>
      list.where((f) => f.key != key).toList();
}
