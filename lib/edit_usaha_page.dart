import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/business_provider.dart';

class EditUsahaPage extends StatefulWidget {
  const EditUsahaPage({super.key});

  @override
  State<EditUsahaPage> createState() => _EditUsahaPageState();
}

class _EditUsahaPageState extends State<EditUsahaPage> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _namaUsahaController;
  late TextEditingController _pemilikController;
  late TextEditingController _alamatController;
  late TextEditingController _teleponController;
  late TextEditingController _emailController;
  late TextEditingController _deskripsiController;
  late TextEditingController _kategoriController;
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    
    _namaUsahaController = TextEditingController();
    _pemilikController = TextEditingController();
    _alamatController = TextEditingController();
    _teleponController = TextEditingController();
    _emailController = TextEditingController();
    _deskripsiController = TextEditingController();
    _kategoriController = TextEditingController();
    
    // Load business data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBusinessData();
    });
  }

  Future<void> _loadBusinessData() async {
    final businessProvider = context.read<BusinessProvider>();
    await businessProvider.fetchBusiness();
    
    final business = businessProvider.business;
    if (business != null) {
      setState(() {
        _namaUsahaController.text = business.namaUsaha;
        _pemilikController.text = business.pemilik;
        _alamatController.text = business.alamat;
        _teleponController.text = business.telepon;
        _emailController.text = business.email ?? '';
        _deskripsiController.text = business.deskripsi ?? '';
        _kategoriController.text = business.kategori;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _namaUsahaController.dispose();
    _pemilikController.dispose();
    _alamatController.dispose();
    _teleponController.dispose();
    _emailController.dispose();
    _deskripsiController.dispose();
    _kategoriController.dispose();
    super.dispose();
  }

  Future<void> _saveBusinessData() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final businessProvider = context.read<BusinessProvider>();
    
    final success = await businessProvider.updateBusiness(
      namaUsaha: _namaUsahaController.text.trim(),
      pemilik: _pemilikController.text.trim(),
      alamat: _alamatController.text.trim(),
      telepon: _teleponController.text.trim(),
      email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
      deskripsi: _deskripsiController.text.trim().isNotEmpty ? _deskripsiController.text.trim() : null,
      kategori: _kategoriController.text.trim().isNotEmpty ? _kategoriController.text.trim() : 'Retail',
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data usaha berhasil disimpan'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(businessProvider.errorMessage ?? 'Gagal menyimpan data'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Info Usaha"),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer<BusinessProvider>(
              builder: (context, businessProvider, child) {
                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header dengan icon
                          Center(
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.store,
                                    size: 60,
                                    color: Colors.blue.shade600,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Informasi Usaha',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Lengkapi data usaha Anda',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 30),

                          // Form Fields
                          _buildTextField(
                            controller: _namaUsahaController,
                            label: 'Nama Usaha',
                            icon: Icons.store_outlined,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Nama usaha wajib diisi';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          _buildTextField(
                            controller: _pemilikController,
                            label: 'Nama Pemilik',
                            icon: Icons.person_outline,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Nama pemilik wajib diisi';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          _buildTextField(
                            controller: _alamatController,
                            label: 'Alamat Usaha',
                            icon: Icons.location_on_outlined,
                            maxLines: 3,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Alamat usaha wajib diisi';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          _buildTextField(
                            controller: _teleponController,
                            label: 'Nomor Telepon',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Nomor telepon wajib diisi';
                              }
                              if (!RegExp(r'^[0-9+\-() ]+$').hasMatch(value)) {
                                return 'Nomor telepon tidak valid';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          _buildTextField(
                            controller: _emailController,
                            label: 'Email (Opsional)',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value != null && value.trim().isNotEmpty) {
                                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                  return 'Email tidak valid';
                                }
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          _buildTextField(
                            controller: _kategoriController,
                            label: 'Kategori Usaha',
                            icon: Icons.category_outlined,
                            hintText: 'Contoh: Retail, F&B, Jasa, dll',
                          ),
                          const SizedBox(height: 16),

                          _buildTextField(
                            controller: _deskripsiController,
                            label: 'Deskripsi Usaha (Opsional)',
                            icon: Icons.description_outlined,
                            maxLines: 4,
                            hintText: 'Jelaskan tentang usaha Anda...',
                          ),
                          const SizedBox(height: 30),

                          // Tombol Simpan
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: businessProvider.isLoading ? null : _saveBusinessData,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: Colors.blue.shade600,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.grey.shade300,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child: businessProvider.isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Text(
                                      "Simpan Perubahan",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hintText,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon, color: Colors.blue.shade600),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
    );
  }
}