class Product {
  final String id;
  final String nama;
  final double harga;
  final int stok;
  final String kategori;
  final String? deskripsi;
  final String? gambar;
  final DateTime createdAt;

  Product({
    required this.id,
    required this.nama,
    required this.harga,
    required this.stok,
    required this.kategori,
    this.deskripsi,
    this.gambar,
    required this.createdAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'].toString(),
      nama: json['nama'],
      harga: double.parse(json['harga'].toString()),
      stok: int.parse(json['stok'].toString()),
      kategori: json['kategori'],
      deskripsi: json['deskripsi'],
      gambar: json['gambar'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': nama,
      'harga': harga,
      'stok': stok,
      'kategori': kategori,
      'deskripsi': deskripsi,
      'gambar': gambar,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Product copyWith({
    String? id,
    String? nama,
    double? harga,
    int? stok,
    String? kategori,
    String? deskripsi,
    String? gambar,
    DateTime? createdAt,
  }) {
    return Product(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      harga: harga ?? this.harga,
      stok: stok ?? this.stok,
      kategori: kategori ?? this.kategori,
      deskripsi: deskripsi ?? this.deskripsi,
      gambar: gambar ?? this.gambar,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}