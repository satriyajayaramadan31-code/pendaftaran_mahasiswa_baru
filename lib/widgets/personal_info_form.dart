import 'package:flutter/material.dart';
import '../utils/validators.dart';

class PersonalInfoForm extends StatelessWidget {
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
    required this.onPickDate,
    required this.nomorHpC,
    required this.nikC,
  });

  final TextEditingController nisnC;
  final TextEditingController namaC;
  final String? jenisKelamin;
  final ValueChanged<String?> onJenisKelaminChanged;
  final String? agama;
  final ValueChanged<String?> onAgamaChanged;
  final TextEditingController tempatC;
  final DateTime? tanggalLahir;
  final VoidCallback onPickDate;
  final TextEditingController nomorHpC;
  final TextEditingController nikC;

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    Widget? prefixIcon,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: prefixIcon,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).inputDecorationTheme.labelStyle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // NISN & Nama
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _buildField(
                label: 'NISN',
                controller: nisnC,
                keyboardType: TextInputType.number,
                validator: (v) => Validators.requiredField(v, fieldName: 'NISN'),
                prefixIcon: const Icon(Icons.badge),
                hint: 'Masukkan NISN',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 5,
              child: _buildField(
                label: 'Nama Lengkap',
                controller: namaC,
                validator: (v) =>
                    Validators.requiredField(v, fieldName: 'Nama Lengkap'),
                prefixIcon: const Icon(Icons.person),
                hint: 'Nama sesuai KTP/akte',
              ),
            ),
          ],
        ),

        // Jenis Kelamin & Agama
        Row(
          children: [
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.only(top: 6.0, bottom: 6.0, right: 8.0),
                child: DropdownButtonFormField<String>(
                  value: jenisKelamin,
                  decoration: InputDecoration(
                    labelText: 'Jenis Kelamin',
                    prefixIcon: const Icon(Icons.wc),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'Laki-laki', child: Text('Laki-laki')),
                    DropdownMenuItem(
                        value: 'Perempuan', child: Text('Perempuan')),
                  ],
                  onChanged: onJenisKelaminChanged,
                  validator: Validators.dropdownRequired('Jenis Kelamin'),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.only(top: 6.0, bottom: 6.0, left: 8.0),
                child: DropdownButtonFormField<String>(
                  value: agama,
                  decoration: InputDecoration(
                    labelText: 'Agama',
                    prefixIcon: const Icon(Icons.menu_book),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Islam', child: Text('Islam')),
                    DropdownMenuItem(
                        value: 'Kristen Protestan',
                        child: Text('Kristen Protestan')),
                    DropdownMenuItem(value: 'Katholik', child: Text('Katholik')),
                    DropdownMenuItem(value: 'Hindu', child: Text('Hindu')),
                    DropdownMenuItem(value: 'Buddha', child: Text('Buddha')),
                    DropdownMenuItem(
                        value: 'Konghucu', child: Text('Konghucu')),
                  ],
                  onChanged: onAgamaChanged,
                  validator: Validators.dropdownRequired('Agama'),
                ),
              ),
            ),
          ],
        ),

        // Tempat & Tanggal Lahir
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _buildField(
                label: 'Tempat Lahir',
                controller: tempatC,
                validator: (v) =>
                    Validators.requiredField(v, fieldName: 'Tempat Lahir'),
                prefixIcon: const Icon(Icons.location_on),
                hint: 'Kota / kabupaten',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: GestureDetector(
                  onTap: onPickDate,
                  child: AbsorbPointer(
                    child: TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Tanggal Lahir',
                        prefixIcon: const Icon(Icons.calendar_today),
                        hintText: tanggalLahir == null
                            ? 'Pilih tanggal'
                            : '${tanggalLahir!.day}/${tanggalLahir!.month}/${tanggalLahir!.year}',
                      ),
                      validator: (_) => (tanggalLahir == null)
                          ? 'Pilih tanggal lahir'
                          : null,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        // No HP & NIK
        Row(
          children: [
            Expanded(
              child: _buildField(
                label: 'No. HP',
                controller: nomorHpC,
                keyboardType: TextInputType.phone,
                validator: Validators.phone,
                prefixIcon: const Icon(Icons.phone),
                hint: 'Contoh: 0812xxxx',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildField(
                label: 'NIK',
                controller: nikC,
                keyboardType: TextInputType.number,
                validator: Validators.nik,
                prefixIcon: const Icon(Icons.badge_outlined),
                hint: '16 digit NIK',
              ),
            ),
          ],
        ),

        const SizedBox(height: 4),
        Text(
          'Pastikan nomor HP aktif — akan digunakan untuk verifikasi jika diperlukan.',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }
}
