import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart'; // animasi sederhana untuk efek masuk
import '../widgets/personal_info_form.dart'; // Form input data pribadi siswa
import '../widgets/address_form.dart'; // Form input alamat
import '../widgets/parents_form.dart'; // Form input data orang tua/wali
import '../services/firestore_service.dart'; // Service untuk menyimpan data ke Firestore
import '../models/student.dart'; // Model data siswa

/// Halaman wizard multi-step untuk registrasi / penambahan siswa.
/// - Tidak mengubah logika apapun; hanya komentar ditambahkan.
/// - Struktur: 3 langkah (Personal, Alamat, Orang Tua/Wali).
class StudentFormWizardPage extends StatefulWidget {
  const StudentFormWizardPage({super.key});

  @override
  State<StudentFormWizardPage> createState() => _StudentFormWizardPageState();
}

class _StudentFormWizardPageState extends State<StudentFormWizardPage> {
  // Indeks langkah saat ini (0..2)
  int _currentStep = 0;

  // Keys untuk tiap form agar bisa memanggil validate() per-step
  final List<GlobalKey<FormState>> _formKeys = [
    GlobalKey<FormState>(), // step 0: PersonalInfoForm
    GlobalKey<FormState>(), // step 1: AddressForm
    GlobalKey<FormState>(), // step 2: ParentsForm
  ];

  // -------------------------
  // Personal info controllers
  // -------------------------
  // Controller untuk field NISN
  final nisnC = TextEditingController();
  // Controller untuk field Nama
  final namaC = TextEditingController();
  // Dropdown / pilihan jenis kelamin (null artinya belum dipilih)
  String? jenisKelamin;
  // Dropdown / pilihan agama (null artinya belum dipilih)
  String? agama;
  // Controller untuk tempat lahir
  final tempatC = TextEditingController();
  // Tanggal lahir disimpan sebagai DateTime (null jika belum dipilih)
  DateTime? tanggalLahir;
  // Controller untuk nomor HP
  final nomorHpC = TextEditingController();
  // Controller untuk NIK
  final nikC = TextEditingController();

  // -------------------------
  // Address controllers
  // -------------------------
  final jalanC = TextEditingController();
  final rtRwC = TextEditingController();
  final dusunC = TextEditingController();
  final desaC = TextEditingController();
  final kecamatanC = TextEditingController();
  final kabupatenC = TextEditingController();
  final provinsiC = TextEditingController();
  final kodePosC = TextEditingController();

  // -------------------------
  // Parents controllers
  // -------------------------
  final namaAyahC = TextEditingController();
  final namaIbuC = TextEditingController();
  final namaWaliC = TextEditingController();
  final alamatWaliC = TextEditingController();

  // Flag loading saat proses penyimpanan sedang berjalan
  bool _saving = false;

  @override
  void dispose() {
    // Dispose semua controller untuk mencegah memory leak saat widget di-destroy
    nisnC.dispose();
    namaC.dispose();
    tempatC.dispose();
    nomorHpC.dispose();
    nikC.dispose();

    jalanC.dispose();
    rtRwC.dispose();
    dusunC.dispose();
    desaC.dispose();
    kecamatanC.dispose();
    kabupatenC.dispose();
    provinsiC.dispose();
    kodePosC.dispose();

    namaAyahC.dispose();
    namaIbuC.dispose();
    namaWaliC.dispose();
    alamatWaliC.dispose();

    super.dispose();
  }

  /// Fungsi untuk melanjutkan ke langkah berikutnya.
  /// - Validasi form pada langkah saat ini.
  /// - Untuk langkah 0 (personal), juga cek nilai dropdown / tanggal.
  void _next() {
    final form = _formKeys[_currentStep].currentState;
    // Jika form tidak valid, show SnackBar dan jangan lanjut
    if (form == null || !form.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Periksa kembali field yang wajib')),
      );
      return;
    }

    // Validasi tambahan khusus di step 0 (pilihan dropdown & tanggal)
    if (_currentStep == 0) {
      if (jenisKelamin == null || jenisKelamin!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih jenis kelamin')),
        );
        return;
      }
      if (agama == null || agama!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih agama')),
        );
        return;
      }
      if (tanggalLahir == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih tanggal lahir')),
        );
        return;
      }
    }

    // Jika belum di langkah terakhir, naikkan indeks langkah
    if (_currentStep < 2) {
      setState(() => _currentStep += 1);
    }
  }

  /// Kembali satu langkah. Jika sudah di langkah 0, close / pop halaman.
  void _back() {
    if (_currentStep > 0) {
      setState(() => _currentStep -= 1);
    } else {
      // Jika berada di awal wizard, kembali (pop) ke layar sebelumnya jika ada
      Navigator.of(context).maybePop();
    }
  }

  /// Submit / simpan data siswa ke Firestore.
  /// - Validasi form terakhir
  /// - Bentuk objek Student lalu panggil FirestoreService().addStudent(student)
  Future<void> _submit() async {
    final form = _formKeys[2].currentState;
    if (form == null || !form.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Periksa kembali field yang wajib')),
      );
      return;
    }

    // Pastikan tanggal lahir ada (di-check lagi sebelum kirim)
    if (tanggalLahir == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tanggal lahir tidak boleh kosong')),
      );
      return;
    }

    // Tampilkan loading
    setState(() => _saving = true);

    // Susun model Student dari semua input
    final student = Student(
      nisn: nisnC.text.trim(),
      nama: namaC.text.trim(),
      jenisKelamin: jenisKelamin ?? '',
      agama: agama ?? '',
      tempatLahir: tempatC.text.trim(),
      tanggalLahir: tanggalLahir,
      noHp: nomorHpC.text.trim(),
      nik: nikC.text.trim(),
      alamat: Address(
        jalan: jalanC.text.trim(),
        rtRw: rtRwC.text.trim(),
        dusun: dusunC.text.trim(),
        desa: desaC.text.trim(),
        kecamatan: kecamatanC.text.trim(),
        kabupaten: kabupatenC.text.trim(),
        provinsi: provinsiC.text.trim(),
        kodePos: kodePosC.text.trim(),
      ),
      orangTuaWali: Parents(
        namaAyah: namaAyahC.text.trim(),
        namaIbu: namaIbuC.text.trim(),
        namaWali: namaWaliC.text.trim(),
        alamatWali: alamatWaliC.text.trim(),
      ),
      createdAt: DateTime.now(),
    );

    try {
      // Panggil service untuk menyimpan ke server (Firestore)
      await FirestoreService().addStudent(student);
      if (!mounted) return;
      // Beri feedback sukses
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data tersimpan ke server')),
      );
      // Tutup halaman dan kembalikan true supaya caller tahu ada perubahan
      Navigator.of(context).pop(true);
    } catch (e) {
      // Jika gagal, tampilkan pesan error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal simpan: $e')));
      }
    } finally {
      // Matikan loading
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Membangun indikator langkah (visual dots, connector bar, dan persentase).
  /// - stepDot: helper untuk membuat dot angka / check
  /// - menampilkan progress line yang terisi sesuai _currentStep
  Widget _buildStepIndicator() {
    Widget stepDot(int index, String title) {
      final isActive = index == _currentStep;
      final isDone = index < _currentStep;
      // Warna border atau isi dot bergantung pada state (done/active/idle)
      final color = isDone ? Colors.teal : (isActive ? Colors.teal : Colors.grey.shade300);

      return Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            // Dot sedikit lebih besar saat aktif
            width: isActive ? 46 : 38,
            height: isActive ? 46 : 38,
            decoration: BoxDecoration(
              // Jika sudah selesai, isi dot warna teal; jika belum => putih
              color: isDone ? Colors.teal : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: color, width: 2),
              // Shadow kecil saat aktif
              boxShadow: isActive ? [BoxShadow(color: Colors.teal.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))] : [],
            ),
            child: Center(
              child: isDone
                  // Jika selesai, tampilkan ikon cek
                  ? const Icon(Icons.check, color: Colors.white)
                  // Jika belum, tampilkan angka langkah (1-based)
                  : Text('${index + 1}', style: TextStyle(fontWeight: FontWeight.bold, color: isActive ? Colors.teal : Colors.grey.shade700)),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 72,
            child: Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: isActive || isDone ? Colors.black87 : Colors.black45)),
          ),
        ],
      );
    }

    // Persentase progress (0..1) berdasarkan langkah saat ini
    final percent = (_currentStep + 1) / 3;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
          child: Row(
            children: [
              // Dot step 1 (Personal)
              stepDot(0, 'Personal'),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6.0),
                  child: Column(
                    children: [
                      // Connector line pertama: background + animated fill sesuai percent
                      Stack(
                        children: [
                          Container(height: 6, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(6))),
                          LayoutBuilder(builder: (context, constraints) {
                            final width = constraints.maxWidth;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 450),
                              width: width * (percent.clamp(0.0, 1.0)),
                              height: 6,
                              decoration: BoxDecoration(color: Colors.teal, borderRadius: BorderRadius.circular(6)),
                            );
                          }),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Dot step 2 (Alamat)
              stepDot(1, 'Alamat'),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6.0),
                  child: Column(
                    children: [
                      // Connector line kedua: memakai perhitungan percent2 (dari step 2 menuju 3)
                      Stack(
                        children: [
                          Container(height: 6, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(6))),
                          LayoutBuilder(builder: (context, constraints) {
                            final width = constraints.maxWidth;
                            // percent2 diatur agar mengindikasikan progress antar step
                            final percent2 = ((_currentStep) / 2).clamp(0.0, 1.0);
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 450),
                              width: width * percent2,
                              height: 6,
                              decoration: BoxDecoration(color: Colors.teal, borderRadius: BorderRadius.circular(6)),
                            );
                          }),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Dot step 3 (Ortu / Wali)
              stepDot(2, 'Ortu / Wali'),
            ],
          ),
        ),
        // Bar progress linear di bawah dots (duplikasi visual untuk kejelasan)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: percent,
                  color: Colors.teal,
                  backgroundColor: Colors.teal.shade100.withOpacity(0.4),
                  minHeight: 6,
                ),
              ),
              const SizedBox(width: 12),
              // Teks "x/3"
              Text(
                '${(_currentStep + 1)}/3',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Membuat konten sesuai langkah saat ini:
  /// - step 0: PersonalInfoForm (dengan Form key dan controller)
  /// - step 1: AddressForm
  /// - step 2: ParentsForm
  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return Form(
          key: _formKeys[0],
          child: PersonalInfoForm(
            nisnC: nisnC,
            namaC: namaC,
            jenisKelamin: jenisKelamin,
            onJenisKelaminChanged: (v) => setState(() => jenisKelamin = v),
            agama: agama,
            onAgamaChanged: (v) => setState(() => agama = v),
            tempatC: tempatC,
            tanggalLahir: tanggalLahir,
            onTanggalLahirChanged: (val) => setState(() => tanggalLahir = val),
            nomorHpC: nomorHpC,
            nikC: nikC,
          ),
        );
      case 1:
        return Form(
          key: _formKeys[1],
          child: AddressForm(
            jalanC: jalanC,
            rtRwC: rtRwC,
            dusunC: dusunC,
            desaC: desaC,
            kecamatanC: kecamatanC,
            kabupatenC: kabupatenC,
            provinsiC: provinsiC,
            kodePosC: kodePosC,
          ),
        );
      case 2:
        return Form(
          key: _formKeys[2],
          child: ParentsForm(
            namaAyahC: namaAyahC,
            namaIbuC: namaIbuC,
            namaWaliC: namaWaliC,
            alamatWaliC: alamatWaliC,
          ),
        );
      default:
        // fallback defensif: jika _currentStep di luar rentang, tampilkan kosong
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Latar belakang gradient lembut
    const bgGradient = LinearGradient(
      colors: [Color(0xFFe8f7f7), Color(0xFFd0f0f2)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Scaffold(
      // extend body agar gradient tampil sampai di bawah AppBar transparan
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Form Registrasi Siswa'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).maybePop()),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: bgGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
            child: Column(
              children: [
                // Animasi fade in untuk indikator langkah
                FadeInDown(child: _buildStepIndicator()),
                const SizedBox(height: 12),
                // Teks kecil menunjukkan langkah X dari 3
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Langkah ${_currentStep + 1} dari 3',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ),
                const SizedBox(height: 12),
                // Konten utama card yang berubah sesuai langkah (menggunakan animated key untuk efek)
                Expanded(
                  child: ZoomIn(
                    key: ValueKey<int>(_currentStep), // memicu animasi saat langkah berubah
                    duration: const Duration(milliseconds: 450),
                    child: Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 10,
                      shadowColor: Colors.black26,
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: _buildStepContent(), // content per-step
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Tombol aksi: Batal/Kembali + Selanjutnya/Selesai
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _back,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.teal,
                            side: BorderSide(color: Colors.teal.shade200),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          // Jika di langkah awal, label tombol adalah 'Batal', jika bukan => 'Kembali'
                          child: Text(_currentStep == 0 ? 'Batal' : 'Kembali'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _saving
                            // Jika sedang menyimpan, tampilkan tombol disabled dengan spinner
                            ? ElevatedButton.icon(
                                onPressed: null,
                                icon: const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                                label: const Text('Menyimpan...'),
                                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                              )
                            // Jika tidak menyimpan, tombol aktif: jalankan _next atau _submit tergantung langkah
                            : ElevatedButton(
                                onPressed: _currentStep == 2 ? _submit : _next,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(_currentStep == 2 ? 'Selesai' : 'Selanjutnya'),
                                    const SizedBox(width: 8),
                                    Icon(_currentStep == 2 ? Icons.check : Icons.arrow_forward, size: 18),
                                  ],
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
