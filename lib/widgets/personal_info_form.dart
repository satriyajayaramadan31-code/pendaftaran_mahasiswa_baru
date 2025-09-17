import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/validators.dart';

/// Form untuk mengisi data pribadi siswa
/// Mendukung responsive: HP = vertikal, Tablet/Desktop = multi kolom
class PersonalInfoForm extends StatefulWidget {
  const PersonalInfoForm({
    super.key,
    required this.nisnC,
    required this.namaC,
    required this.jenisKelamin,
    required this.onJenisKelaminChanged,
    required this.agama,
    required this.onAgamaChanged,
    required this.tempatC,
    required this.tanggalLahir,
    required this.onTanggalLahirChanged,
    required this.nomorHpC,
    required this.nikC,
  });

  // Controller untuk input NISN
  final TextEditingController nisnC;
  // Controller untuk input nama lengkap
  final TextEditingController namaC;
  // Nilai dropdown jenis kelamin saat ini
  final String? jenisKelamin;
  // Callback ketika dropdown jenis kelamin berubah
  final ValueChanged<String?> onJenisKelaminChanged;
  // Nilai dropdown agama saat ini
  final String? agama;
  // Callback ketika dropdown agama berubah
  final ValueChanged<String?> onAgamaChanged;
  // Controller untuk input tempat lahir
  final TextEditingController tempatC;
  // Nilai tanggal lahir saat ini
  final DateTime? tanggalLahir;
  // Callback ketika tanggal lahir dipilih
  final ValueChanged<DateTime> onTanggalLahirChanged;
  // Controller untuk input nomor HP
  final TextEditingController nomorHpC;
  // Controller untuk input NIK
  final TextEditingController nikC;

  @override
  State<PersonalInfoForm> createState() => _PersonalInfoFormState();
}

class _PersonalInfoFormState extends State<PersonalInfoForm> {
  // Format tanggal untuk ditampilkan di field
  final dateFormat = DateFormat("dd MMM yyyy");
  // Controller internal untuk field tanggal lahir (readonly)
  late final TextEditingController _tanggalC;

  @override
  void initState() {
    super.initState();
    // Inisialisasi text controller tanggal lahir dengan format string
    _tanggalC = TextEditingController(
      text: widget.tanggalLahir != null ? dateFormat.format(widget.tanggalLahir!) : '',
    );
  }

  /// Method untuk menampilkan date picker dan memperbarui field
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.tanggalLahir ?? DateTime(2005),
      firstDate: DateTime(1970),
      lastDate: DateTime.now(),
      helpText: "Pilih Tanggal Lahir",
    );

    if (picked != null) {
      // Update controller dan callback jika user memilih tanggal
      setState(() {
        _tanggalC.text = dateFormat.format(picked);
      });
      widget.onTanggalLahirChanged(picked);
    }
  }

  /// Helper untuk style InputDecoration agar konsisten di semua field
  InputDecoration _inputDecoration({
    required String label,
    String? hint,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: Colors.grey.shade100,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.teal, width: 2),
      ),
    );
  }

  /// Helper untuk membuat TextFormField dengan validator dan style konsisten
  Widget _buildField({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    Widget? prefixIcon,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        validator: validator, // Validasi sesuai kebutuhan
        keyboardType: keyboardType,
        decoration: _inputDecoration(
          label: label,
          hint: hint,
          prefixIcon: prefixIcon,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Cek lebar layar untuk responsive layout
    final isNarrow = MediaQuery.of(context).size.width < 480;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== NISN & Nama Lengkap =====
            isNarrow
                ? Column(
                    children: [
                      // Field NISN
                      _buildField(
                        label: 'NISN',
                        controller: widget.nisnC,
                        keyboardType: TextInputType.number,
                        validator: (v) => Validators.requiredField(v, fieldName: 'NISN'),
                        prefixIcon: const Icon(Icons.badge),
                        hint: 'Masukkan NISN',
                      ),
                      // Field Nama Lengkap
                      _buildField(
                        label: 'Nama Lengkap',
                        controller: widget.namaC,
                        validator: (v) => Validators.requiredField(v, fieldName: 'Nama Lengkap'),
                        prefixIcon: const Icon(Icons.person),
                        hint: 'Nama sesuai KTP/akte',
                      ),
                    ],
                  )
                : Row(
                    children: [
                      // NISN di kolom kiri
                      Expanded(
                        flex: 2,
                        child: _buildField(
                          label: 'NISN',
                          controller: widget.nisnC,
                          keyboardType: TextInputType.number,
                          validator: (v) => Validators.requiredField(v, fieldName: 'NISN'),
                          prefixIcon: const Icon(Icons.badge),
                          hint: 'Masukkan NISN',
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Nama Lengkap di kolom kanan
                      Expanded(
                        flex: 5,
                        child: _buildField(
                          label: 'Nama Lengkap',
                          controller: widget.namaC,
                          validator: (v) => Validators.requiredField(v, fieldName: 'Nama Lengkap'),
                          prefixIcon: const Icon(Icons.person),
                          hint: 'Nama sesuai KTP/akte',
                        ),
                      ),
                    ],
                  ),

            const SizedBox(height: 16),

            // ===== Jenis Kelamin & Agama =====
            isNarrow
                ? Column(
                    children: [
                      // Dropdown jenis kelamin
                      DropdownButtonFormField<String>(
                        value: widget.jenisKelamin,
                        decoration: _inputDecoration(
                          label: 'Jenis Kelamin',
                          prefixIcon: const Icon(Icons.wc),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Laki-laki', child: Text('Laki-laki')),
                          DropdownMenuItem(value: 'Perempuan', child: Text('Perempuan')),
                        ],
                        onChanged: widget.onJenisKelaminChanged,
                        validator: Validators.dropdownRequired('Jenis Kelamin'),
                      ),
                      const SizedBox(height: 12),
                      // Dropdown agama
                      DropdownButtonFormField<String>(
                        value: widget.agama,
                        decoration: _inputDecoration(
                          label: 'Agama',
                          prefixIcon: const Icon(Icons.menu_book),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Islam', child: Text('Islam')),
                          DropdownMenuItem(value: 'Kristen Protestan', child: Text('Kristen Protestan')),
                          DropdownMenuItem(value: 'Katholik', child: Text('Katholik')),
                          DropdownMenuItem(value: 'Hindu', child: Text('Hindu')),
                          DropdownMenuItem(value: 'Buddha', child: Text('Buddha')),
                          DropdownMenuItem(value: 'Konghucu', child: Text('Konghucu')),
                        ],
                        onChanged: widget.onAgamaChanged,
                        validator: Validators.dropdownRequired('Agama'),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      // Dropdown jenis kelamin di kolom kiri
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: widget.jenisKelamin,
                          decoration: _inputDecoration(
                            label: 'Jenis Kelamin',
                            prefixIcon: const Icon(Icons.wc),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Laki-laki', child: Text('Laki-laki')),
                            DropdownMenuItem(value: 'Perempuan', child: Text('Perempuan')),
                          ],
                          onChanged: widget.onJenisKelaminChanged,
                          validator: Validators.dropdownRequired('Jenis Kelamin'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Dropdown agama di kolom kanan
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: widget.agama,
                          decoration: _inputDecoration(
                            label: 'Agama',
                            prefixIcon: const Icon(Icons.menu_book),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Islam', child: Text('Islam')),
                            DropdownMenuItem(value: 'Kristen Protestan', child: Text('Kristen Protestan')),
                            DropdownMenuItem(value: 'Katholik', child: Text('Katholik')),
                            DropdownMenuItem(value: 'Hindu', child: Text('Hindu')),
                            DropdownMenuItem(value: 'Buddha', child: Text('Buddha')),
                            DropdownMenuItem(value: 'Konghucu', child: Text('Konghucu')),
                          ],
                          onChanged: widget.onAgamaChanged,
                          validator: Validators.dropdownRequired('Agama'),
                        ),
                      ),
                    ],
                  ),

            const SizedBox(height: 16),

            // ===== Tempat & Tanggal Lahir =====
            isNarrow
                ? Column(
                    children: [
                      // Field tempat lahir
                      _buildField(
                        label: 'Tempat Lahir',
                        controller: widget.tempatC,
                        validator: (v) => Validators.requiredField(v, fieldName: 'Tempat Lahir'),
                        prefixIcon: const Icon(Icons.location_on),
                        hint: 'Kota / kabupaten',
                      ),
                      // Field tanggal lahir (readonly, trigger date picker)
                      TextFormField(
                        controller: _tanggalC,
                        readOnly: true,
                        onTap: _pickDate,
                        decoration: _inputDecoration(
                          label: 'Tanggal Lahir',
                          prefixIcon: const Icon(Icons.calendar_today),
                          hint: 'Pilih tanggal',
                        ),
                        validator: (_) => (widget.tanggalLahir == null) ? 'Pilih tanggal lahir' : null,
                      ),
                    ],
                  )
                : Row(
                    children: [
                      // Tempat lahir di kolom kiri
                      Expanded(
                        flex: 2,
                        child: _buildField(
                          label: 'Tempat Lahir',
                          controller: widget.tempatC,
                          validator: (v) => Validators.requiredField(v, fieldName: 'Tempat Lahir'),
                          prefixIcon: const Icon(Icons.location_on),
                          hint: 'Kota / kabupaten',
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Tanggal lahir di kolom kanan
                      Expanded(
                        flex: 1,
                        child: TextFormField(
                          controller: _tanggalC,
                          readOnly: true,
                          onTap: _pickDate,
                          decoration: _inputDecoration(
                            label: 'Tanggal Lahir',
                            prefixIcon: const Icon(Icons.calendar_today),
                            hint: 'Pilih tanggal',
                          ),
                          validator: (_) => (widget.tanggalLahir == null) ? 'Pilih tanggal lahir' : null,
                        ),
                      ),
                    ],
                  ),

            const SizedBox(height: 16),

            // ===== No HP & NIK =====
            isNarrow
                ? Column(
                    children: [
                      // Field nomor HP
                      _buildField(
                        label: 'No. HP',
                        controller: widget.nomorHpC,
                        keyboardType: TextInputType.phone,
                        validator: Validators.phone,
                        prefixIcon: const Icon(Icons.phone),
                        hint: 'Contoh: 0812xxxx',
                      ),
                      // Field NIK
                      _buildField(
                        label: 'NIK',
                        controller: widget.nikC,
                        keyboardType: TextInputType.number,
                        validator: Validators.nik,
                        prefixIcon: const Icon(Icons.badge_outlined),
                        hint: '16 digit NIK',
                      ),
                    ],
                  )
                : Row(
                    children: [
                      // No HP di kolom kiri
                      Expanded(
                        child: _buildField(
                          label: 'No. HP',
                          controller: widget.nomorHpC,
                          keyboardType: TextInputType.phone,
                          validator: Validators.phone,
                          prefixIcon: const Icon(Icons.phone),
                          hint: 'Contoh: 0812xxxx',
                        ),
                      ),
                      const SizedBox(width: 12),
                      // NIK di kolom kanan
                      Expanded(
                        child: _buildField(
                          label: 'NIK',
                          controller: widget.nikC,
                          keyboardType: TextInputType.number,
                          validator: Validators.nik,
                          prefixIcon: const Icon(Icons.badge_outlined),
                          hint: '16 digit NIK',
                        ),
                      ),
                    ],
                  ),

            const SizedBox(height: 12),

            // Catatan tambahan di bawah form
            Text(
              'Pastikan nomor HP aktif — akan digunakan untuk verifikasi jika diperlukan.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
