class Business {
  final String id;
  final String namaUsaha;
  final String pemilik;
  final String alamat;
  final String telepon;
  final String? email;
  final String? deskripsi;
  final String kategori;
  final String? logo;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Business({
    required this.id,
    required this.namaUsaha,
    required this.pemilik,
    required this.alamat,
    required this.telepon,
    this.email,
    this.deskripsi,
    required this.kategori,
    this.logo,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Business.fromJson(Map<String, dynamic> json) {
    return Business(
      id: json['id'].toString(),
      namaUsaha: json['nama_usaha'] ?? '',
      pemilik: json['pemilik'] ?? '',
      alamat: json['alamat'] ?? '',
      telepon: json['telepon'] ?? '',
      email: json['email'],
      deskripsi: json['deskripsi'],
      kategori: json['kategori'] ?? 'Retail',
      logo: json['logo'],
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama_usaha': namaUsaha,
      'pemilik': pemilik,
      'alamat': alamat,
      'telepon': telepon,
      'email': email,
      'deskripsi': deskripsi,
      'kategori': kategori,
      'logo': logo,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
