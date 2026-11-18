import 'package:linefm_radio/domain/favorite.dart';

enum ExportFormat { csv, text }

/// Export (CSV mit BOM und Semikolon, Text). Stub, wird in P02 ausgebaut.
class FavoritesExport {
  const FavoritesExport._();

  static String build(List<Favorite> favorites, ExportFormat format) {
    throw UnimplementedError('P02: FavoritesExport.build');
  }
}
