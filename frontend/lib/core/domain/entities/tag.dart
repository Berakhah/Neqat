class Tag {
  final String id;
  final String name;
  final String? description;

  Tag({
    required this.id,
    required this.name,
    this.description,
  });

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      id: json['id'],
      name: json['name'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
    };
  }
} 