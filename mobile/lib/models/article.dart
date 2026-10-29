class Article {
  final String id, title, summary, body, status;
  final String? categoryName;
  final List<String> tags, imageUrls;
  final DateTime updatedAt;
  Article({
    required this.id, required this.title, required this.summary, required this.body,
    required this.status, required this.categoryName, required this.tags,
    required this.imageUrls, required this.updatedAt,
  });
  factory Article.fromMap(Map<String, dynamic> map) => Article(
    id: map['id'] as String,
    title: map['title'] as String? ?? '',
    summary: map['summary'] as String? ?? '',
    body: map['body'] as String? ?? '',
    status: map['status'] as String? ?? 'published',
    categoryName: map['categories']?['name'] as String?,
    tags: List<String>.from(map['tags'] ?? const []),
    imageUrls: List<String>.from(map['image_urls'] ?? const []),
    updatedAt: DateTime.tryParse(map['updated_at']?.toString() ?? '') ?? DateTime.now(),
  );
}
