import 'pick_item.dart';

/// A walkable part of the unit - `C3-Front`, `C3-Back`, `C1` - with its own tally.
///
/// Areas are derived from the bays the server actually returns rather than from a
/// hardcoded list. Retired areas stop appearing on their own once they hold no
/// stock, and a bay in an area nobody thought to configure still shows up instead
/// of being silently dropped from every list.
class PickArea {
  const PickArea({
    required this.name,
    required this.total,
    required this.remaining,
  });

  final String name;
  final int total;
  final int remaining;

  int get picked => total - remaining;

  bool get isClear => remaining == 0;

  double get progress => total == 0 ? 0 : picked / total;

  /// The area a bay belongs to: everything before a trailing bay number.
  /// `C3-Front-02` -> `C3-Front`, `C1-05` -> `C1`, `C3-Amazon` -> `C3-Amazon`.
  static String of(String location) {
    final List<String> parts = location.split('-');
    if (parts.length > 1 && RegExp(r'^\d+$').hasMatch(parts.last)) {
      return parts.sublist(0, parts.length - 1).join('-');
    }
    return location;
  }

  /// Builds the area tallies for [items], keeping first-seen order so the list
  /// does not reshuffle under a picker between refreshes.
  static List<PickArea> from(Iterable<PickItem> items) {
    final Map<String, int> totals = <String, int>{};
    final Map<String, int> remaining = <String, int>{};

    for (final PickItem item in items) {
      final String area = of(item.location);
      totals[area] = (totals[area] ?? 0) + 1;
      remaining[area] = (remaining[area] ?? 0) + (item.isPicked ? 0 : 1);
    }

    return totals.keys
        .map((String name) => PickArea(
              name: name,
              total: totals[name]!,
              remaining: remaining[name]!,
            ),)
        .toList();
  }
}
