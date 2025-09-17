import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'pages/student_list_page.dart';
import 'package:registrasi_siswa/firebase_option.dart'; // jika kamu pakai flutterfire configure

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); 
  // Pastikan Flutter binding sudah diinisialisasi sebelum menggunakan async/await atau plugin

  // jika kamu pakai flutterfire configure, gunakan initializeApp dengan options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // konfigurasi Firebase sesuai platform
  );

  runApp(const MyApp()); // jalankan aplikasi Flutter
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData.light(); // gunakan tema dasar light
    // modifikasi color scheme primary dan secondary
    final colorScheme = base.colorScheme.copyWith(
      primary: Colors.indigo, 
      secondary: Colors.teal
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false, // hilangkan banner debug
      title: 'Registrasi Siswa', // judul aplikasi
      theme: base.copyWith(
        colorScheme: colorScheme, // terapkan color scheme
        scaffoldBackgroundColor: const Color(0xFFF6F8FB), // warna background scaffold
        inputDecorationTheme: const InputDecorationTheme(
          filled: true, 
          fillColor: Colors.white, // warna background input field
          contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12), // padding dalam field
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)), // border melengkung
          ),
        ),
      ),
      home: const StudentListPage(), // halaman utama aplikasi
    );
  }
}
