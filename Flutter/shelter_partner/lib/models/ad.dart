class Ad {
  final String id;
  final List<String> imageUrls;
  final String productName;
  final String productUrl;

  Ad({
    required this.id,
    required this.imageUrls,
    required this.productName,
    required this.productUrl,
  });

  factory Ad.fromMap(Map<String, dynamic> data, String documentId) {
    return Ad(
      id: documentId,
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      productName: data['productName'] ?? '',
      productUrl: data['productUrl'] ?? '',
    );
  }
}
