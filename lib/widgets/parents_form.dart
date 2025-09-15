import 'package:flutter/material.dart';

class ParentsForm extends StatelessWidget {
  const ParentsForm({
    super.key,
    required this.namaAyahC,
    required this.namaIbuC,
    required this.namaWaliC,
    required this.alamatWaliC,
  });

  final TextEditingController namaAyahC;
  final TextEditingController namaIbuC;
  final TextEditingController namaWaliC;
  final TextEditingController alamatWaliC;

  Widget _field({
    required String label,
    required TextEditingController controller,
    String? hint,
    Widget? prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
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
    final sectionTitleStyle = TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[800]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Data Orang Tua / Wali', style: sectionTitleStyle),
        const SizedBox(height: 8),

        // Nama Ayah & Nama Ibu
        Row(
          children: [
            Expanded(
              child: _field(
                label: 'Nama Ayah',
                controller: namaAyahC,
                hint: 'Nama lengkap ayah',
                prefixIcon: const Icon(Icons.male),
                validator: (v) => (v == null || v.trim().isEmpty) ? null : null, // optional; gunakan validator di parent jika perlu
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _field(
                label: 'Nama Ibu',
                controller: namaIbuC,
                hint: 'Nama lengkap ibu',
                prefixIcon: const Icon(Icons.female),
              ),
            ),
          ],
        ),

        // Nama Wali (jika ada) & alamat wali
        Row(
          children: [
            Expanded(
              child: _field(
                label: 'Nama Wali (opsional)',
                controller: namaWaliC,
                hint: 'Isi jika ada wali',
                prefixIcon: const Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _field(
                    label: 'Alamat Wali (jika ada)',
                    controller: alamatWaliC,
                    hint: 'Alamat lengkap wali / kontak darurat',
                    prefixIcon: const Icon(Icons.home_outlined),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 6),
        Text(
          'Isi data wali hanya jika berbeda dengan orang tua. Alamat wali akan dipakai untuk keperluan darurat.',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }
}
