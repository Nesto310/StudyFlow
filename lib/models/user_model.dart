class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String email;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        email: json['email'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );
}
