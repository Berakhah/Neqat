class Tag {
  final String id;
  final String name;
  final String? description;

  const Tag({
    required this.id, 
    required this.name, 
    this.description,
  });

  @override
  String toString() => name;
  
  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is Tag &&
    runtimeType == other.runtimeType &&
    id == other.id;

  @override
  int get hashCode => id.hashCode;
} 