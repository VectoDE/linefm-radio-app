import 'package:linefm_radio/domain/track.dart';

/// Links zu Musikdiensten (Spec 2.2). Apple Music nutzt trackViewUrl aus dem
/// iTunes-Treffer, die anderen sind Such-Links.
class MusicLinks {
  const MusicLinks._();

  static String _query(Track t) =>
      Uri.encodeQueryComponent('${t.artist} ${t.title}');

  static Uri spotify(Track t) => Uri.parse(
    'https://open.spotify.com/search/${Uri.encodeComponent('${t.artist} ${t.title}')}',
  );

  static Uri youtubeMusic(Track t) =>
      Uri.parse('https://music.youtube.com/search?q=${_query(t)}');

  static Uri? appleMusic(String? trackViewUrl) =>
      trackViewUrl == null ? null : Uri.tryParse(trackViewUrl);
}
