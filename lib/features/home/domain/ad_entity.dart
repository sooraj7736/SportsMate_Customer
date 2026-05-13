class AdEntity {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String link;
  final bool isActive;

  const AdEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.link,
    this.isActive = true,
  });

  factory AdEntity.fromMap(Map<String, dynamic> map, String docId) {
    return AdEntity(
      id: docId,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      link: map['link'] ?? '',
      isActive: map['isActive'] ?? true,
    );
  }
}
