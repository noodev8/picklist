import 'package:flutter/foundation.dart';

import '../api/get_picks_api.dart';
import '../api/set_amazon_picked_api.dart';
import '../api/set_picked_api.dart';
import '../core/utils/auth_error_handler.dart';
import '../models/pick_area.dart';
import '../models/pick_item.dart';
import '../models/pick_mode.dart';

/// Holds the current pick run.
///
/// The whole run is fetched in one call and everything after that - area tallies,
/// bay grouping, per-area lists - is derived from that one list in memory. The
/// previous version made a call per configured area on top of a call for the
/// totals, which meant five round trips to build a screen and areas that could
/// disagree with each other halfway through.
class PicklistProvider with ChangeNotifier {
  /// One list per job. A picker does customer picks or Amazon picks, never both
  /// at once, and the two lists never overlap.
  final Map<PickMode, List<PickItem>> _itemsByMode = <PickMode, List<PickItem>>{
    for (final PickMode mode in PickMode.values) mode: <PickItem>[],
  };

  final Map<PickMode, bool> _loadedByMode = <PickMode, bool>{
    for (final PickMode mode in PickMode.values) mode: false,
  };

  /// Items with a pick in flight, so a row can show it is working and a second
  /// tap cannot race the first.
  final Set<String> _inFlight = <String>{};

  PickMode _mode = PickMode.customer;
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _lastLoaded;

  PickMode get mode => _mode;
  bool get isAmazonMode => _mode == PickMode.amazon;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime? get lastLoaded => _lastLoaded;
  bool get hasLoaded => _loadedByMode[_mode]!;

  List<PickItem> get items => _itemsByMode[_mode]!;

  bool isInFlight(String id) => _inFlight.contains(id);

  /// Areas in the current run, in bay order.
  List<PickArea> get areas => PickArea.from(items);

  int get total => items.length;
  int get remaining => items.where((PickItem i) => !i.isPicked).length;
  int get picked => total - remaining;

  /// Items in one area, or the whole run when [area] is null. Ordered the way a
  /// picker walks it: bay by bay, then by the pick order the server assigns.
  List<PickItem> itemsForArea(String? area) {
    final List<PickItem> result = area == null
        ? List<PickItem>.of(items)
        : items.where((PickItem i) => PickArea.of(i.location) == area).toList();

    result.sort((PickItem a, PickItem b) {
      final int byBay = a.location.compareTo(b.location);
      if (byBay != 0) return byBay;
      final int byOrder = a.pickOrder.compareTo(b.pickOrder);
      if (byOrder != 0) return byOrder;
      return a.productCode.compareTo(b.productCode);
    });

    return result;
  }

  int remainingIn(String? area) =>
      itemsForArea(area).where((PickItem i) => !i.isPicked).length;

  /// Loads the whole run for the active job.
  ///
  /// [silent] leaves the loading flag alone, for a pull-to-refresh that already
  /// has its own spinner.
  Future<void> load({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final List<PickItem> picks = await GetPicksApi.getAllPicks(mode: _mode);
      _itemsByMode[_mode] = picks;
      _loadedByMode[_mode] = true;
      _lastLoaded = DateTime.now();
      _errorMessage = null;
    } on AuthenticationException {
      _errorMessage = 'Session expired. Log in again.';
      rethrow;
    } catch (e) {
      _errorMessage = _readable(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Switches job and loads that job's run. The outgoing job's list is dropped so
  /// coming back to it re-reads the server rather than showing a stale tally.
  Future<void> setMode(PickMode mode) async {
    if (_mode == mode) return;

    _itemsByMode[_mode] = <PickItem>[];
    _loadedByMode[_mode] = false;
    _mode = mode;
    _errorMessage = null;
    notifyListeners();

    await load();
  }

  /// Picks or unpicks [id].
  ///
  /// The row flips immediately and the call goes out behind it, so a pick lands
  /// at walking pace even on warehouse wifi. A failure puts the row back the way
  /// it was and reports why. Returns the state the item ended up in.
  Future<bool> toggle(String id) async {
    final int index = items.indexWhere((PickItem i) => i.id == id);
    if (index == -1) return false;

    final PickItem item = items[index];
    if (_inFlight.contains(id)) return item.isPicked;

    final bool wasPicked = item.isPicked;
    item.isPicked = !wasPicked;
    _inFlight.add(id);
    _errorMessage = null;
    notifyListeners();

    try {
      if (_mode == PickMode.amazon) {
        await SetAmazonPickedApi.togglePickedStatus(
          item.id,
          wasPicked,
          item.location,
        );
      } else {
        await SetPickedApi.togglePickedStatus(item.id, wasPicked);
      }
      return item.isPicked;
    } on AuthenticationException {
      item.isPicked = wasPicked;
      _errorMessage = 'Session expired. Log in again.';
      rethrow;
    } catch (e) {
      item.isPicked = wasPicked;
      _errorMessage = _readable(e);
      return item.isPicked;
    } finally {
      _inFlight.remove(id);
      notifyListeners();
    }
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  /// Drops everything on logout.
  void reset() {
    for (final PickMode mode in PickMode.values) {
      _itemsByMode[mode] = <PickItem>[];
      _loadedByMode[mode] = false;
    }
    _inFlight.clear();
    _mode = PickMode.customer;
    _isLoading = false;
    _errorMessage = null;
    _lastLoaded = null;
    notifyListeners();
  }

  /// Strips the `Exception:` prefixes the API layer stacks up, so what reaches a
  /// picker reads like a sentence.
  String _readable(Object error) {
    String message = error.toString();
    while (message.startsWith('Exception: ')) {
      message = message.substring('Exception: '.length);
    }
    return message;
  }
}
