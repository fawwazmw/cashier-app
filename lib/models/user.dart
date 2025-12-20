class User {
  final String id;
  final String username;
  final String nama;
  final String role; // 'admin' or 'kasir'
  final String? email;
  final String? phone;
  final DateTime createdAt;

  User({
    required this.id,
    required this.username,
    required this.nama,
    required this.role,
    this.email,
    this.phone,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'].toString(),
      username: json['username'],
      nama: json['nama'],
      role: json['role'],
      email: json['email'],
      phone: json['phone'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'nama': nama,
      'role': role,
      'email': email,
      'phone': phone,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isAdmin => role.toLowerCase() == 'admin';
  bool get isKasir => role.toLowerCase() == 'kasir';
}