import 'package:flutter/material.dart';
import '../widgets/personal_info_form.dart';
import '../widgets/address_form.dart';
import '../widgets/parents_form.dart';
import '../models/student.dart';

class StudentFormPage extends StatefulWidget {
  const StudentFormPage({super.key});

  @override
  State<StudentFormPage> createState() => _StudentFormPageState();
}

class _StudentFormPageState extends State<StudentFormPage> {
  final _formKey = GlobalKey<FormState>();

  // Personal controllers
  final TextEditingController nisnC = TextEditingController();
  final TextEditingController namaC = TextEditingController();
  String? jenisKelamin;
  String? agama;
  final TextEditingController tempatC = TextEditingController();
  DateTime? tanggalLahir;
  final TextEditingController nomorHpC = TextEditingController();
  final TextEditingController nikC = TextEditingController();

  // Address controllers
  final TextEditingController jalanC = TextEditingController();
  final TextEditingController rtRwC = TextEditingController();
  final TextEditingController dusunC = TextEditingController();
  final TextEditingController desaC = TextEditingController();
  final TextEditingController kecamatanC = TextEditingController();
  final TextEditingController kabupatenC = TextEditingController();
  final TextEditingController provinsiC = TextEditingController();
  final TextEditingController kodePosC = TextEditingController();

  // Parents controllers
  final TextEditingController namaAyahC = TextEditingController();
  final TextEditingController namaIbuC = TextEditingController();
  final TextEditingController namaWaliC = TextEditingController();
  final TextEditingController alamatWaliC = TextEditingController();

  @override
  void dispose() {
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

  // Use a void callback that triggers the date picker (keeps signature simple for widgets)
  void _pickDate() {
    final now = DateTime.now();
    showDatePicker(
      context: context,
      initialDate: tanggalLahir ?? DateTime(now.year - 10),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
    ).then((picked) {
      if (picked != null) setState(() => tanggalLahir = picked);
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      // scroll to top or show snackbar for guidance
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Periksa kembali data yang wajib diisi')),
      );
      return;
    }

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
    );

    // For now show a neat dialog with summary
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(children: const [Icon(Icons.check_circle, color: Colors.green), SizedBox(width: 8), Text('Berhasil')]),
        content: SingleChildScrollView(child: Text(student.toString())),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Tutup')),
        ],
      ),
    );
  }

  Widget _sectionCard({required IconData icon, required String title, required Widget child}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.all(8),
                  child: Icon(icon, color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Constrain width for large screens for nicer appearance
    final maxWidth = MediaQuery.of(context).size.width > 900 ? 900.0 : double.infinity;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Form Pendaftaran Siswa'),
        elevation: 1,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _sectionCard(
                      icon: Icons.person,
                      title: 'Informasi Pribadi',
                      child: PersonalInfoForm(
                        nisnC: nisnC,
                        namaC: namaC,
                        jenisKelamin: jenisKelamin,
                        onJenisKelaminChanged: (v) => setState(() => jenisKelamin = v),
                        agama: agama,
                        onAgamaChanged: (v) => setState(() => agama = v),
                        tempatC: tempatC,
                        tanggalLahir: tanggalLahir,
                        onPickDate: _pickDate,
                        nomorHpC: nomorHpC,
                        nikC: nikC,
                      ),
                    ),
                    _sectionCard(
                      icon: Icons.home,
                      title: 'Alamat',
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
                    ),
                    _sectionCard(
                      icon: Icons.family_restroom,
                      title: 'Orang Tua / Wali',
                      child: ParentsForm(
                        namaAyahC: namaAyahC,
                        namaIbuC: namaIbuC,
                        namaWaliC: namaWaliC,
                        alamatWaliC: alamatWaliC,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              // reset form quickly
                              _formKey.currentState?.reset();
                              setState(() {
                                jenisKelamin = null;
                                agama = null;
                                tanggalLahir = null;
                              });
                              // clear controllers
                              nisnC.clear();
                              namaC.clear();
                              tempatC.clear();
                              nomorHpC.clear();
                              nikC.clear();
                              jalanC.clear();
                              rtRwC.clear();
                              dusunC.clear();
                              desaC.clear();
                              kecamatanC.clear();
                              kabupatenC.clear();
                              provinsiC.clear();
                              kodePosC.clear();
                              namaAyahC.clear();
                              namaIbuC.clear();
                              namaWaliC.clear();
                              alamatWaliC.clear();
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reset'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: _submit,
                            icon: const Icon(Icons.save),
                            label: const Text('Simpan Data'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Tip: Pastikan semua field wajib terisi sebelum menekan "Simpan Data".',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
