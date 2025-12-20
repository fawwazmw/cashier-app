import 'package:flutter/material.dart';
import 'profil_page.dart';

class UbahPinPage extends StatelessWidget {
  const UbahPinPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff8f8f8),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tombol kembali dan judul
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'Ubah PIN',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              buildPinSection('Tuliskan PIN lama anda'),
              buildPinSection('Tuliskan PIN baru anda'),
              buildPinSection('Konfirmasi PIN baru anda'),
              const Spacer(),

              // Tombol Simpan
              ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfilPage()),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff1E88E5),
                  minimumSize: const Size.fromHeight(50),
                ),
                child: const Text('Simpan',
                    style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildPinSection(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style:
                const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            6,
            (index) => Container(
              width: 40,
              height: 50,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}