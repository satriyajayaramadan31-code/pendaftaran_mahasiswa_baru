import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart'; // ✨ animasi sederhana untuk efek masuk (fade, zoom, dsb)
import '../widgets/personal_info_form.dart'; // Form input data pribadi siswa
import '../widgets/address_form.dart'; // Form input alamat
import '../widgets/parents_form.dart'; // Form input data orang tua/wali
import '../services/firestore_service.dart'; // Service untuk menyimpan data ke Firestore
import '../models/student.dart'; // Model data siswa

class StudentFormWizardPage extends StatefulWidget {
  const StudentFormWizardPage({super.key});

  @override
  State<StudentFormWizardPage> createState() => _StudentFormWizardPageState();
}

class _StudentFormWizardPageState extends State<StudentFormWizardPage> {
  int _currentStep = 0; // Menyimpan step/form yang sedang aktif

  // Key untuk tiap Form agar bisa divalidasi dan diakses secara terpisah
  final List<GlobalKey<FormState>> _formKeys = [
    GlobalKey<FormState>(), // Step 1: Personal Info
    GlobalKey<FormState>(), // Step 2: Address
    GlobalKey<FormState>(), // Step 3: Parents/Wali
  ];

  // Controllers untuk form input personal info
  final nisnC = TextEditingController();
  final namaC = TextEditingController();
  String? jenisKelamin;
  String? agama;
  final tempatC = TextEditingController();
  DateTime? tanggalLahir;
  final nomorHpC = TextEditingController();
  final nikC = TextEditingController();

  // Controllers untuk form input alamat
  final jalanC = TextEditingController();
  final rtRwC = TextEditingController();
  final dusunC = TextEditingController();
  final desaC = TextEditingController();
  final kecamatanC = TextEditingController();
  final kabupatenC = TextEditingController();
  final provinsiC = TextEditingController();
  final kodePosC = TextEditingController();

  // Controllers untuk form input orang tua/wali
  final namaAyahC = TextEditingController();
  final namaIbuC = TextEditingController();
  final namaWaliC = TextEditingController();
  final alamatWaliC = TextEditingController();

  bool _saving = false; // Flag untuk menampilkan loading saat menyimpan

  @override
  void dispose() {
    // Dispose semua controller agar tidak memory leak
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

  // Fungsi untuk melanjutkan ke step berikutnya
  void _next() {
    final form = _formKeys[_currentStep].currentState;
    if (form == null || !form.validate()) {
      // Jika form belum valid, tampilkan SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Periksa kembali field yang wajib')),
      );
      return;
    }

    // Validasi tambahan untuk step pertama (personal info)
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

    // Pindah ke step berikutnya jika belum sampai step terakhir
    if (_currentStep < 2) {
      setState(() => _currentStep += 1);
    }
  }

  // Fungsi untuk kembali ke step sebelumnya
  void _back() {
    if (_currentStep > 0) {
      setState(() => _currentStep -= 1);
    } else {
      Navigator.of(context).maybePop(); // Jika step pertama, keluar halaman
    }
  }

  // Fungsi submit form terakhir dan simpan ke Firestore
  Future<void> _submit() async {
    final form = _formKeys[2].currentState; // Ambil form step 3
    if (form == null || !form.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Periksa kembali field yang wajib')),
      );
      return;
    }

    if (tanggalLahir == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tanggal lahir tidak boleh kosong')),
      );
      return;
    }

    setState(() => _saving = true); // Tampilkan loading

    // Buat objek Student dari semua field
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
      await FirestoreService().addStudent(student); // Simpan ke Firestore
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data tersimpan ke server')),
      );
      Navigator.of(context).pop(true); // Kembali ke halaman sebelumnya
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal simpan: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false); // Hapus loading
    }
  }

  // Widget untuk menampilkan indikator step di atas form
  Widget _buildStepIndicator() {
    Widget circle(int index, String label) {
      final isActive = index == _currentStep; // Step yang sedang aktif
      final isDone = index < _currentStep; // Step yang sudah selesai
      final color = isActive || isDone ? Colors.teal : Colors.grey.shade400;

      return Expanded(
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutBack,
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isDone
                    ? Colors.teal
                    : (isActive ? Colors.white : Colors.grey.shade200),
                borderRadius: BorderRadius.circular(21),
                border: Border.all(color: color, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: isActive
                        ? Colors.teal.withOpacity(0.3)
                        : Colors.transparent,
                    blurRadius: 1,
                    offset: isActive ? const Offset(0, 3) : const Offset(0, 0),
                  )
                ],
              ),
              child: Center(
                child: isDone
                    ? const Icon(Icons.check, color: Colors.white)
                    : Text(
                        '${index + 1}', // Nomor step
                        style: TextStyle(
                          color:
                              isActive ? Colors.teal : Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(fontSize: 12, color: color)),
          ],
        ),
      );
    }

    return Row(
      children: [
        circle(0, 'Personal'),
        const SizedBox(width: 8),
        circle(1, 'Alamat'),
        const SizedBox(width: 8),
        circle(2, 'Ortu / Wali'),
      ],
    );
  }

  // Widget untuk menampilkan form sesuai step saat ini
  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        // Step 1: Form Personal Info
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
            onTanggalLahirChanged: (val) =>
                setState(() => tanggalLahir = val),
            nomorHpC: nomorHpC,
            nikC: nikC,
          ),
        );
      case 1:
        // Step 2: Form Address
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
        // Step 3: Form Parents/Wali
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
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // Membuat body di bawah AppBar transparan
      appBar: AppBar(
        title: const Text('Form Registrasi Siswa'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).maybePop(), // Tutup halaman
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFe0f7fa),
              Color(0xFF80deea),
              Color(0xFF26c6da),
              Color(0xFF00acc1)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              FadeInDown(child: _buildStepIndicator()), // Animasi step indicator
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Langkah ${_currentStep + 1} dari 3',
                  style: const TextStyle(
                      fontSize: 12, color: Colors.black87),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ZoomIn(
                  key: ValueKey<int>(_currentStep), // Animasi per step
                  duration: const Duration(milliseconds: 500),
                  child: Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 6,
                    shadowColor: Colors.black26,
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SingleChildScrollView(
                        child: _buildStepContent(), // Isi form step saat ini
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _back, // Tombol kembali / batal
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.teal,
                          side: const BorderSide(color: Colors.teal),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child:
                            Text(_currentStep == 0 ? 'Batal' : 'Kembali'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _saving
                          ? ElevatedButton.icon(
                              onPressed: null, // Disable saat loading
                              icon: const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white),
                              ),
                              label: const Text('Menyimpan...'),
                            )
                          : ElevatedButton(
                              onPressed:
                                  _currentStep == 2 ? _submit : _next, // Submit jika step terakhir
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                minimumSize:
                                    const Size.fromHeight(48),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(10)),
                              ),
                              child: Text(_currentStep == 2
                                  ? 'Selesai'
                                  : 'Selanjutnya'),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
