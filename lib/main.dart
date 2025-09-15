import 'package:flutter/material.dart';
import 'pages/student_form_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData.light();
    final colorScheme = base.colorScheme.copyWith(
      primary: Colors.indigo,
      secondary: Colors.teal,
    );

    return MaterialApp(
      title: 'Pendaftaran Siswa',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        colorScheme: colorScheme,
        primaryColor: colorScheme.primary,
        scaffoldBackgroundColor: const Color(0xFFF6F8FB),
        appBarTheme: AppBarTheme(
          backgroundColor: colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 2,
          centerTitle: true,
          titleTextStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          labelStyle: const TextStyle(fontWeight: FontWeight.w500),
        ),
        dividerColor: Colors.grey.shade300,
      ),
      home: const StudentFormPage(),
    );
  }
}
