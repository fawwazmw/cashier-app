import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _namaUsahaController = TextEditingController();
  final _alamatUsahaController = TextEditingController();
  final _nomorHPController = TextEditingController();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  
  bool _isLoading = false;
  int _currentStep = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _namaUsahaController.dispose();
    _alamatUsahaController.dispose();
    _nomorHPController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Daftar Akun Baru',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              // Progress Indicator
              _buildProgressIndicator(),
              
              // Form Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Step Title
                        _buildStepTitle(),
                        const SizedBox(height: 24),
                        
                        // Step Content
                        _buildStepContent(),
                        const SizedBox(height: 32),
                        
                        // Buttons
                        _buildButtons(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          _buildProgressStep(0, 'Info Usaha', Icons.store),
          _buildProgressLine(0),
          _buildProgressStep(1, 'Kontak', Icons.phone),
          _buildProgressLine(1),
          _buildProgressStep(2, 'Keamanan', Icons.lock),
        ],
      ),
    );
  }

  Widget _buildProgressStep(int step, String label, IconData icon) {
    final isActive = _currentStep >= step;
    final isCurrent = _currentStep == step;
    
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isActive ? Colors.blue.shade600 : Colors.grey.shade200,
              shape: BoxShape.circle,
              boxShadow: isCurrent ? [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ] : null,
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.white : Colors.grey.shade400,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
              color: isActive ? Colors.blue.shade700 : Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressLine(int step) {
    final isActive = _currentStep > step;
    
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 32),
        decoration: BoxDecoration(
          color: isActive ? Colors.blue.shade600 : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }

  Widget _buildStepTitle() {
    final titles = [
      'Informasi Usaha Anda',
      'Informasi Kontak',
      'Buat PIN Keamanan',
    ];
    
    final subtitles = [
      'Masukkan detail usaha Anda',
      'Bagaimana kami bisa menghubungi Anda?',
      'Buat PIN 6 digit untuk keamanan akun',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titles[_currentStep],
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitles[_currentStep],
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildBusinessInfoStep();
      case 1:
        return _buildContactInfoStep();
      case 2:
        return _buildSecurityStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildBusinessInfoStep() {
    return Column(
      children: [
        _buildTextField(
          controller: _namaUsahaController,
          label: 'Nama Usaha',
          hint: 'Contoh: Toko Serbaguna',
          icon: Icons.store_outlined,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Nama usaha tidak boleh kosong';
            }
            if (value.length < 3) {
              return 'Nama usaha minimal 3 karakter';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _alamatUsahaController,
          label: 'Alamat Usaha',
          hint: 'Jl. Contoh No. 123',
          icon: Icons.location_on_outlined,
          maxLines: 3,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Alamat usaha tidak boleh kosong';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildContactInfoStep() {
    return Column(
      children: [
        _buildTextField(
          controller: _nomorHPController,
          label: 'Nomor Handphone',
          hint: '08123456789',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(13),
          ],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Nomor HP tidak boleh kosong';
            }
            if (value.length < 10) {
              return 'Nomor HP minimal 10 digit';
            }
            if (!value.startsWith('08')) {
              return 'Nomor HP harus diawali 08';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Nomor HP akan digunakan untuk verifikasi dan notifikasi penting',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityStep() {
    return Column(
      children: [
        _buildPinField(
          controller: _pinController,
          label: 'Buat PIN',
          hint: 'Masukkan 6 digit PIN',
        ),
        const SizedBox(height: 16),
        _buildPinField(
          controller: _confirmPinController,
          label: 'Konfirmasi PIN',
          hint: 'Masukkan ulang PIN',
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Konfirmasi PIN tidak boleh kosong';
            }
            if (value != _pinController.text) {
              return 'PIN tidak cocok';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.security, color: Colors.orange.shade700, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Tips PIN Aman',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.orange.shade700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '• Gunakan kombinasi angka yang tidak mudah ditebak\n'
                '• Jangan gunakan tanggal lahir atau urutan angka\n'
                '• Simpan PIN dengan aman',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange.shade900,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.blue.shade400),
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
          borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
    );
  }

  Widget _buildPinField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(Icons.pin_outlined, color: Colors.blue.shade400),
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
          borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      keyboardType: TextInputType.number,
      obscureText: true,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(6),
      ],
      validator: validator ?? (value) {
        if (value == null || value.isEmpty) {
          return 'PIN tidak boleh kosong';
        }
        if (value.length != 6) {
          return 'PIN harus 6 digit';
        }
        return null;
      },
    );
  }

  Widget _buildButtons() {
    return Column(
      children: [
        if (_currentStep > 0)
          OutlinedButton(
            onPressed: _isLoading ? null : () {
              setState(() {
                _currentStep--;
              });
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue.shade600,
              side: BorderSide(color: Colors.blue.shade600),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              minimumSize: const Size(double.infinity, 56),
            ),
            child: const Text(
              'Kembali',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        if (_currentStep > 0) const SizedBox(height: 12),
        SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleNextOrSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              shadowColor: Colors.blue.withOpacity(0.4),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _currentStep == 2 ? 'Daftar Sekarang' : 'Lanjutkan',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(_currentStep == 2 ? Icons.check : Icons.arrow_forward, size: 20),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  void _handleNextOrSubmit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
        _animationController.reset();
        _animationController.forward();
      });
    } else {
      _handleRegister();
    }
  }

  Future<void> _handleRegister() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    // Show success dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: Colors.green.shade600,
                size: 64,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Pendaftaran Berhasil!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Akun Anda telah dibuat.\nSilakan login untuk melanjutkan.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Back to login
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                'Ke Halaman Login',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
