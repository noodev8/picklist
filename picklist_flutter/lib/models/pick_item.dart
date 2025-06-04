class PickItem {
  final String id;
  final String productCode;
  final String location;
  final String title;
  final String? imageUrl;
  bool isPicked;

  PickItem({
    required this.id,
    required this.productCode,
    required this.location,
    required this.title,
    this.imageUrl,
    this.isPicked = false,
  });
}

// Dummy data generator for pick items with multiple items per rack location
List<PickItem> getDummyPickItems(String locationId) {
  final items = <PickItem>[];

  // Define realistic rack locations based on main location
  List<String> rackLocations = _getRackLocationsForMainLocation(locationId);

  // Product categories for variety
  final productCategories = [
    'Running Shoes', 'Sport Socks', 'T-Shirt', 'Shorts', 'Hoodie',
    'Sneakers', 'Jacket', 'Pants', 'Cap', 'Gloves', 'Backpack',
    'Water Bottle', 'Towel', 'Headband', 'Wristband', 'Sweatshirt',
    'Leggings', 'Tank Top', 'Polo Shirt', 'Jeans', 'Sandals'
  ];

  final colors = ['Blue', 'Red', 'Black', 'White', 'Green', 'Gray', 'Navy', 'Pink', 'Orange', 'Purple'];
  final sizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];

  int itemId = 1;

  // Generate multiple items per rack location to create realistic grouping
  for (int rackIndex = 0; rackIndex < rackLocations.length; rackIndex++) {
    final rack = rackLocations[rackIndex];

    // Each rack gets 3-7 items (weighted towards more items in first few racks)
    int itemsInThisRack;
    if (rackIndex == 0) {
      itemsInThisRack = 5 + (locationId.hashCode % 3); // 5-7 items in first rack
    } else if (rackIndex == 1) {
      itemsInThisRack = 4 + (locationId.hashCode % 3); // 4-6 items in second rack
    } else if (rackIndex == 2) {
      itemsInThisRack = 3 + (locationId.hashCode % 3); // 3-5 items in third rack
    } else {
      itemsInThisRack = 3 + (locationId.hashCode % 2); // 3-4 items in remaining racks
    }

    // Generate items for this specific rack
    for (int i = 0; i < itemsInThisRack; i++) {
      final color = colors[itemId % colors.length];
      final product = productCategories[itemId % productCategories.length];
      final size = sizes[itemId % sizes.length];

      // Add size to clothing items for more variety
      final needsSize = ['T-Shirt', 'Shorts', 'Hoodie', 'Jacket', 'Pants',
                        'Sweatshirt', 'Leggings', 'Tank Top', 'Polo Shirt', 'Jeans'];
      final title = needsSize.contains(product)
          ? '$color $product ($size)'
          : '$color $product';

      items.add(
        PickItem(
          id: '${locationId}_$itemId',
          productCode: 'SKU${1000 + itemId}',
          location: rack,
          title: title,
          imageUrl: 'https://example.com/product$itemId.jpg',
        ),
      );
      itemId++;
    }
  }

  return items;
}

// Helper function to get rack locations based on main location
List<String> _getRackLocationsForMainLocation(String locationId) {
  switch (locationId) {
    case 'c3f': // C3-Front
      return [
        'C3-Front-Rack-01',
        'C3-Front-Rack-02',
        'C3-Front-Rack-03',
        'C3-Front-Basket-01',
        'C3-Front-Shelf-01'
      ];
    case 'c3b': // C3-Back
      return [
        'C3-Back-Rack-01',
        'C3-Back-Rack-02',
        'C3-Back-Rack-03',
        'C3-Back-Rack-04',
        'C3-Back-Basket-01'
      ];
    case 'c3c': // C3-Crocs
      return [
        'C3-Crocs-Rack-01',
        'C3-Crocs-Rack-02',
        'C3-Crocs-Display-01'
      ];
    case 'c3s': // C3-Shop
      return [
        'C3-Shop-Rack-01',
        'C3-Shop-Rack-02',
        'C3-Shop-Counter-01',
        'C3-Shop-Display-01'
      ];
    case 'c1': // C1
      return [
        'C1-Rack-01',
        'C1-Rack-02',
        'C1-Rack-03',
        'C1-Rack-04',
        'C1-Rack-05',
        'C1-Basket-01',
        'C1-Shelf-01'
      ];
    default:
      return ['${locationId.toUpperCase()}-Rack-01'];
  }
}
