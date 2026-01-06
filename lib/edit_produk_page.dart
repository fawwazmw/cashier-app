import 'package:flutter/material.dart';
import 'kelola_produk_page.dart';

class EditProdukPage extends StatelessWidget {
  const EditProdukPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Layanan", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
            const TextField(decoration: InputDecoration(hintText: "Cola Coca")),

            const SizedBox(height: 16),
            const Text("Harga Modal", style: TextStyle(fontWeight: FontWeight.bold)),
            const TextField(decoration: InputDecoration(hintText: "Rp6.000")),

            const SizedBox(height: 16),
            const Text("Harga Jual", style: TextStyle(fontWeight: FontWeight.bold)),
            const TextField(decoration: InputDecoration(hintText: "Rp8.000")),

            const SizedBox(height: 16),
            const Text("Jumlah Stock", style: TextStyle(fontWeight: FontWeight.bold)),
            const TextField(decoration: InputDecoration(hintText: "500")),

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
              child: const Text("Perbarui Informasi", style: TextStyle(color: Colors.white)),
            ),

            const SizedBox(height: 8),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[200],
                minimumSize: const Size.fromHeight(50),
              ),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const KelolaProdukPage()),
                );
              },
              child: const Text("Non Aktifkan", style: TextStyle(color: Colors.white)),
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