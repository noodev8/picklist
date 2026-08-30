import 'pick_mode.dart';

/// One line to pick: a single pair, in a single bay.
///
/// The server hands back a product code (`0745531-GIZEH-37`) and a group id
/// (`0745531-GIZEH`). Read together they separate the three things a picker
/// actually needs - the style reference printed on the box end, the model name,
/// and the size - so the UI can lead with the size instead of making someone
/// parse a hyphenated string mid-aisle.
class PickItem {
  PickItem({
    required this.id,
    required this.productCode,
    required this.location,
    required this.orderNum,
    required this.groupId,
    required this.brand,
    required this.supplier,
    required this.colour,
    required this.allocated,
    required this.pickOrder,
    this.isPicked = false,
  });

  /// Builds an item from one `get_picks` row.
  ///
  /// [mode] decides how picked status is read. Customer picks carry it in qty
  /// (0 = picked); Amazon picks leave the list by being moved to the staging
  /// area, so anything the server returns is by definition still to pick and its
  /// qty is not a picked flag at all.
  factory PickItem.fromApiResponse(
    Map<String, dynamic> json, {
    required PickMode mode,
  }) {
    return PickItem(
      id: json['id']?.toString() ?? '',
      productCode: json['code']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      orderNum: json['ordernum']?.toString() ?? '',
      groupId: json['groupid']?.toString() ?? '',
      brand: json['brand']?.toString() ?? '',
      supplier: json['supplier']?.toString() ?? '',
      colour: json['colour']?.toString() ?? '',
      allocated: json['allocated']?.toString() ?? '',
      pickOrder: json['pickorder'] is int ? json['pickorder'] as int : 0,
      isPicked: mode == PickMode.amazon ? false : (json['qty'] ?? 1) == 0,
    );
  }

  final String id;
  final String productCode;

  /// Bay the item is picked from, e.g. `C3-Front-02`. Amazon picks keep showing
  /// their original bay after being picked, which is what makes an undo possible.
  final String location;
  final String orderNum;
  final String groupId;
  final String brand;
  final String supplier;
  final String colour;
  final String allocated;
  final int pickOrder;

  bool isPicked;

  /// The size, taken as whatever the product code carries beyond the group id.
  /// Falls back to the code's last segment, and to an empty string if the code
  /// has no recognisable size on the end.
  String get size {
    if (groupId.isNotEmpty && productCode.startsWith('$groupId-')) {
      return productCode.substring(groupId.length + 1);
    }
    final List<String> parts = productCode.split('-');
    if (parts.length > 1 && RegExp(r'^\d{1,2}[A-Za-z]?$').hasMatch(parts.last)) {
      return parts.last;
    }
    return '';
  }

  /// Style reference as printed on the box end, e.g. `0745531`.
  String get styleRef {
    final List<String> parts = groupId.split('-');
    return parts.isEmpty ? groupId : parts.first;
  }

  /// Model name in plain words, e.g. `GIZEH` -> `Gizeh`, `IVES-NAVY-BLUE` ->
  /// `Ives Navy Blue`.
  String get model {
    final List<String> parts = groupId.split('-');
    if (parts.length < 2) return _titleCase(groupId);
    return parts.skip(1).map(_titleCase).join(' ');
  }

  /// What the row leads with: brand and model, without repeating either.
  String get displayName {
    if (brand.isEmpty) return model;
    if (model.isEmpty) return brand;
    if (model.toLowerCase().startsWith(brand.toLowerCase())) return model;
    return '$brand $model';
  }

  /// Colour is only worth its own chip when the model name has not already said
  /// it - `Ives Navy Blue` does not need a "Navy" chip next to it.
  bool get showsColourSeparately =>
      colour.isNotEmpty &&
      !model.toLowerCase().contains(colour.toLowerCase());

  /// The bay a pick sits in, e.g. `C3-Front-02` -> `02`.
  String get bay {
    final List<String> parts = location.split('-');
    if (parts.length > 1 && RegExp(r'^\d+$').hasMatch(parts.last)) {
      return parts.last;
    }
    return location;
  }

  static String _titleCase(String word) {
    if (word.isEmpty) return word;
    return word[0].toUpperCase() + word.substring(1).toLowerCase();
  }
}
