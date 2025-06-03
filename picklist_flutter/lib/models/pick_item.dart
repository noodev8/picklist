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

// Dummy data generator for pick items
List<PickItem> getDummyPickItems(String locationId) {
  final items = [
    PickItem(
      id: '${locationId}_1',
      productCode: 'SKU123',
      location: 'A1-B2',
      title: 'Blue Running Shoes',
      imageUrl: 'https://example.com/shoe1.jpg',
    ),
    PickItem(
      id: '${locationId}_2',
      productCode: 'SKU456',
      location: 'A1-B3',
      title: 'Red Sport Socks',
      imageUrl: 'https://example.com/socks1.jpg',
    ),
    // Add more dummy items...
  ];

  // Generate more items based on locationId
  for (int i = 3; i <= 10; i++) {
    items.add(
      PickItem(
        id: '${locationId}_$i',
        productCode: 'SKU${i}00',
        location: 'A${i}-B${i}',
        title: 'Product $i',
        imageUrl: 'https://example.com/product$i.jpg',
      ),
    );
  }

  return items;
}
