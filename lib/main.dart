import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'splash_screen.dart';
import 'login_page.dart';
import 'register_page.dart';
import 'main_navigation_page.dart';
import 'profil_page.dart';
import 'pengaturan_profil_page.dart';
import 'ubah_pin_page.dart';
import 'kasir_page.dart';
import 'kelola_produk_page.dart';
import 'riwayat_page.dart';
import 'transaksi_page.dart';
import 'pembayaran_page.dart';
import 'tambah_produk_page.dart';
import 'edit_produk_page.dart';
import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';
import 'providers/transaction_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Indonesian locale for date formatting
  await initializeDateFormatting('id_ID', null);
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Griyo POS',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          fontFamily: 'Arial',
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            elevation: 2,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          snackBarTheme: const SnackBarThemeData(
            behavior: SnackBarBehavior.floating,
            showCloseIcon: true,
          ),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginPage(),
          '/register': (context) => const RegisterPage(),
          '/home': (context) => const MainNavigationPage(initialIndex: 0),
          '/riwayat': (context) => const MainNavigationPage(initialIndex: 1),
          '/usahaku': (context) => const MainNavigationPage(initialIndex: 2),
          '/profil': (context) => const MainNavigationPage(initialIndex: 3),
          '/pengaturan-profil': (context) => const PengaturanProfilPage(),
          '/ubah-pin': (context) => const UbahPinPage(),
          '/kasir': (context) => const KasirPage(),
          '/kelola-produk': (context) => const KelolaProdukPage(),
          '/tambah-produk': (context) => const TambahProdukPage(),
          '/edit-produk': (context) => const EditProdukPage(),
          '/transaksi': (context) => const TransaksiPage(),
          '/pembayaran': (context) => const PembayaranPage(),
        },
      ),
    );
  }
}