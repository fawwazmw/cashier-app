import 'package:flutter/material.dart';
import 'ubah_pin_page.dart';
import 'profil_page.dart';

class PengaturanProfilPage extends StatelessWidget {
  const PengaturanProfilPage({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController statusController =
        TextEditingController(text: 'Pemilik Toko');
    final TextEditingController namaController =
        TextEditingController(text: 'Nolan');
    final TextEditingController emailController =
        TextEditingController(text: 'nul@gmail.com');
    final TextEditingController hpController =
        TextEditingController(text: '0895421323233');

    return Scaffold(
      backgroundColor: const Color(0xfff8f8f8),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tombol kembali + judul
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    const Text(
                      'Pengaturan Profil',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // Input Fields
                buildTextField('Status', statusController),
                buildTextField('Nama Pengguna', namaController),
                buildTextField('Email', emailController),
                buildTextField('Nomor Handphone', hpController),
                const SizedBox(height: 30),

                // Tombol Ubah PIN
                OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const UbahPinPage()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    side: const BorderSide(color: Color(0xff1E88E5)),
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: const Text(
                    'Ubah PIN',
                    style: TextStyle(color: Color(0xff1E88E5), fontSize: 16),
                  ),
                ),
                const SizedBox(height: 15),

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
      ),
    );
  }

  Widget buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 5),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              fillColor: Colors.white,
              filled: true,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
    );
  }
}