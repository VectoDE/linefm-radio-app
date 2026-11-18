import 'package:linefm_radio/domain/track.dart';

class HistoryEntry {
  const HistoryEntry({required this.track, this.isLive = false});

  final Track track;
  final bool isLive;

  HistoryEntry copyWith({Track? track, bool? isLive}) =>
      HistoryEntry(track: track ?? this.track, isLive: isLive ?? this.isLive);

  @override
  bool operator ==(Object other) =>
      other is HistoryEntry && other.track == track && other.isLive == isLive;

  @override
  int get hashCode => Object.hash(track, isLive);
}
