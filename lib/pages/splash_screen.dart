import 'dart:async';
import 'package:flutter/material.dart';
import 'student_list_page.dart';

/// SplashScreen menampilkan animasi logo dan judul sebelum masuk ke halaman daftar siswa
/// Animasi termasuk scale, rotate, fade, dan pulse icon
class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // Controller utama untuk semua animasi
  late final AnimationController _controller;

  // Animasi scale logo
  late final Animation<double> _scaleAnim;

  // Animasi rotasi logo
  late final Animation<double> _rotationAnim;

  // Animasi fade untuk teks
  late final Animation<double> _fadeAnim;

  // Animasi pulse untuk icon kecil
  late final Animation<double> _iconPulseAnim;

  @override
  void initState() {
    super.initState();

    // Inisialisasi controller animasi
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );

    // Scale animasi dengan efek elastis
    _scaleAnim = Tween<double>(begin: 0.64, end: 1.12).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.55, curve: Curves.elasticOut)),
    );

    // Rotasi animasi sedikit dari -0.06 rad ke 0
    _rotationAnim = Tween<double>(begin: -0.06, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.12, 0.62, curve: Curves.easeOut)),
    );

    // Fade in teks judul dan subjudul
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.62, 1.0, curve: Curves.easeIn)),
    );

    // Pulse icon untuk memberi kesan hidup dan dinamis
    _iconPulseAnim = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.45, 0.9, curve: Curves.easeInOut)),
    );

    // Mulai animasi
    _controller.forward();

    // Listener untuk berpindah halaman ketika animasi selesai
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Delay sedikit agar user melihat akhir animasi
        Timer(const Duration(milliseconds: 350), () {
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const StudentListPage()),
          );
        });
      }
    });
  }

  @override
  void dispose() {
    // Dispose controller agar tidak memory leak
    _controller.dispose();
    super.dispose();
  }

  /// Membuat gradient background dinamis sesuai progress animasi
  LinearGradient _buildGradient() {
    final t = _controller.value;
    // interpolasi warna dari indigo ke teal
    final colorA = Color.lerp(Colors.indigo.shade700, Colors.teal.shade700, t) ?? Colors.indigo;
    final colorB = Color.lerp(Colors.indigo.shade300, Colors.teal.shade200, t) ?? Colors.teal;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [colorA, colorB],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final logoSize = screenW * 0.36; // ukuran logo proporsional
    final iconSize = logoSize * 0.56; // ukuran icon di dalam logo

    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(gradient: _buildGradient()),
            child: Stack(
              children: [
                // ===== Lingkaran dekoratif bergerak =====
                Positioned(
                  top: 60,
                  left: -40 + (_controller.value * 80),
                  child: Opacity(
                    opacity: (0.22 + _controller.value * 0.78).clamp(0.0, 1.0),
                    child: _DecorCircle(size: 120, blur: 36),
                  ),
                ),
                Positioned(
                  bottom: 40,
                  right: -20 + (_controller.value * 50),
                  child: Opacity(
                    opacity: (0.18 + (_controller.value * 0.6)).clamp(0.0, 1.0),
                    child: _DecorCircle(size: 90, blur: 24),
                  ),
                ),

                // ===== Konten utama di tengah =====
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo utama dengan rotasi dan scale animasi
                      Transform.rotate(
                        angle: _rotationAnim.value,
                        child: Transform.scale(
                          scale: _scaleAnim.value * _iconPulseAnim.value,
                          child: Container(
                            width: logoSize,
                            height: logoSize,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.18 * _controller.value),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Center(
                              // Icon sekolah di tengah
                              child: Icon(
                                Icons.school_rounded,
                                size: iconSize,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Judul dan subjudul muncul dengan fade animasi
                      Opacity(
                        opacity: _fadeAnim.value,
                        child: Column(
                          children: [
                            Text(
                              'Registrasi Siswa',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.6,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Input data siswa cepat & aman',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.white.withOpacity(0.95),
                                  ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Linear progress indicator mengikuti progress animasi
                      SizedBox(
                        width: 160,
                        height: 6,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: (_controller.value < 0.95) ? _controller.value * 1.05 : 1.0,
                            backgroundColor: Colors.white.withOpacity(0.18),
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ===== Footer copyright =====
                Positioned(
                  bottom: 18,
                  left: 18,
                  right: 18,
                  child: Opacity(
                    opacity: 0.85,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '© ${DateTime.now().year} Sekolah Kita',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Lingkaran dekoratif yang digunakan sebagai background animasi
class _DecorCircle extends StatelessWidget {
  final double size; // diameter lingkaran
  final double blur; // radius blur untuk shadow

  const _DecorCircle({Key? key, required this.size, required this.blur}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.06),
            blurRadius: blur,
            spreadRadius: blur / 20,
          ),
        ],
      ),
    );
  }
}
