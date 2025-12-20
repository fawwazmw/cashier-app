import 'package:flutter/material.dart';
import 'usahaku_page.dart';

class EditUsahaPage extends StatelessWidget {
  const EditUsahaPage({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController namaUsahaController =
        TextEditingController(text: "Nul Store");
    final TextEditingController namaPemilikController =
        TextEditingController(text: "Nolan");
    final TextEditingController lokasiController =
        TextEditingController(text: "Jl. Veteran");
    final TextEditingController noHpController =
        TextEditingController(text: "0895421323233");

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // kembali ke Usahaku
          },
        ),
        title: const Text("Edit Info Usaha"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const CircleAvatar(
                radius: 40,
                backgroundColor: Colors.blue,
                child: Icon(Icons.person, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 8),
              const Text(
                "Ganti Foto",
                style: TextStyle(
                    color: Colors.blue, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Form Fields
              TextField(
                controller: namaUsahaController,
                decoration: const InputDecoration(labelText: "Nama Usaha"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: namaPemilikController,
                decoration: const InputDecoration(labelText: "Nama Pemilik"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: lokasiController,
                decoration: const InputDecoration(labelText: "Lokasi Usaha"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noHpController,
                decoration: const InputDecoration(labelText: "Nomor Handphone"),
              ),
              const SizedBox(height: 30),

              // Tombol Simpan
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const UsahakuPage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    "Simpan",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}