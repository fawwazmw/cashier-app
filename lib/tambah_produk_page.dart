import 'package:flutter/material.dart';
import 'kelola_produk_page.dart';

class TambahProdukPage extends StatelessWidget {
  const TambahProdukPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tambah Layanan", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
            const Text("Nama Layanan", style: TextStyle(fontWeight: FontWeight.bold)),
            const TextField(decoration: InputDecoration(hintText: "Nama Layanan Anda")),

            const SizedBox(height: 16),
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue, style: BorderStyle.solid, width: 2),
                borderRadius: BorderRadius.circular(8),
                color: Colors.blue[50],
              ),
              child: const Center(child: Text("Upload Foto")),
            ),

            const SizedBox(height: 16),
            const Text("Harga Jual", style: TextStyle(fontWeight: FontWeight.bold)),
            const TextField(decoration: InputDecoration(hintText: "Tentukan Harga Jual")),

            const SizedBox(height: 16),
            const Text("Harga Modal", style: TextStyle(fontWeight: FontWeight.bold)),
            const TextField(decoration: InputDecoration(hintText: "Tentukan Harga Modal")),

            const SizedBox(height: 16),
            const Text("Jumlah Stock", style: TextStyle(fontWeight: FontWeight.bold)),
            const TextField(decoration: InputDecoration(hintText: "Tentukan Jumlah Stock")),

            const SizedBox(height: 24),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: const Size.fromHeight(50),
              ),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const KelolaProdukPage()),
                );
              },
              child: const Text("Simpan", style: TextStyle(color: Colors.white)),
            ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}