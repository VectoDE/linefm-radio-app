import 'package:linefm_radio/domain/track.dart';

class HistoryEntry {
  const HistoryEntry({required this.track, this.isLive = false});

  final Track track;
  final bool isLive;
}
