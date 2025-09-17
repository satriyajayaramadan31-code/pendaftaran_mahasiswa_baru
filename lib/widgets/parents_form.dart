import 'package:flutter/material.dart';

/// Form untuk mengisi data orang tua/wali
/// Nama Ayah & Nama Ibu wajib diisi.
/// Mendukung responsive:
/// - HP = vertikal (1 kolom)
/// - Tablet / Desktop = 2 kolom
class ParentsForm extends StatelessWidget {
  const ParentsForm({
    super.key,
    required this.namaAyahC,
    required this.namaIbuC,
    required this.namaWaliC,
    required this.alamatWaliC,
  });

  // Controller untuk masing-masing input
  final TextEditingController namaAyahC;
  final TextEditingController namaIbuC;
  final TextEditingController namaWaliC;
  final TextEditingController alamatWaliC;

  /// Helper method untuk membuat TextFormField dengan style & validator
  /// Parameter:
  /// - label: label field
  /// - controller: controller untuk input
  /// - hint: placeholder
  /// - prefixIcon: icon di depan input
  /// - keyboardType: tipe input (default teks)
  /// - maxLines: jumlah baris input
  /// - isRequired: jika true, field wajib diisi
  Widget _field({
    required String label,
    required TextEditingController controller,
    String? hint,
    Widget? prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool isRequired = false,
  }) {
    final isMultiline = maxLines > 1; // cek apakah input multiline
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: isMultiline ? TextInputType.multiline : keyboardType,
        maxLines: maxLines,
        textInputAction:
            isMultiline ? TextInputAction.newline : TextInputAction.next,
        textCapitalization: TextCapitalization.words,
        // Validator untuk mengecek input wajib
        validator: (val) {
          if (isRequired && (val == null || val.trim().isEmpty)) {
            return "$label wajib diisi";
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: label, // Label field
          hintText: hint, // Placeholder
          prefixIcon: prefixIcon, // Icon di depan field
          isDense: true, // Mengurangi tinggi field
          filled: true, // Background color field
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.blue, width: 1.8),
          ),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Style untuk judul section
    final sectionTitleStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: Colors.blueGrey[800],
    );

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        // LayoutBuilder untuk mendeteksi lebar container dan responsive
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 480; // threshold HP

            if (isNarrow) {
              // Layout HP (vertikal, 1 kolom)
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Data Orang Tua / Wali', style: sectionTitleStyle),
                  const SizedBox(height: 12),
                  // Field Nama Ayah
                  _field(
                    label: 'Nama Ayah',
                    controller: namaAyahC,
                    hint: 'Nama lengkap ayah',
                    prefixIcon: const Icon(Icons.male),
                    isRequired: true,
                  ),
                  // Field Nama Ibu
                  _field(
                    label: 'Nama Ibu',
                    controller: namaIbuC,
                    hint: 'Nama lengkap ibu',
                    prefixIcon: const Icon(Icons.female),
                    isRequired: true,
                  ),
                  // Field Nama Wali (opsional)
                  _field(
                    label: 'Nama Wali (opsional)',
                    controller: namaWaliC,
                    hint: 'Isi jika ada wali',
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  // Field Alamat Wali (opsional, multiline)
                  _field(
                    label: 'Alamat Wali (jika ada)',
                    controller: alamatWaliC,
                    hint: 'Alamat lengkap wali / kontak darurat',
                    prefixIcon: const Icon(Icons.home_outlined),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 8),
                  // Catatan di bawah form
                  Text(
                    'Isi data wali hanya jika berbeda dengan orang tua.\n'
                    'Alamat wali dipakai untuk kontak darurat.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              );
            } else {
              // Layout Tablet / Desktop (2 kolom)
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Data Orang Tua / Wali', style: sectionTitleStyle),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Kolom kiri (Nama Ayah & Nama Ibu)
                      Expanded(
                        child: Column(
                          children: [
                            _field(
                              label: 'Nama Ayah',
                              controller: namaAyahC,
                              hint: 'Nama lengkap ayah',
                              prefixIcon: const Icon(Icons.male),
                              isRequired: true,
                            ),
                            _field(
                              label: 'Nama Ibu',
                              controller: namaIbuC,
                              hint: 'Nama lengkap ibu',
                              prefixIcon: const Icon(Icons.female),
                              isRequired: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Kolom kanan (Nama Wali & Alamat Wali)
                      Expanded(
                        child: Column(
                          children: [
                            _field(
                              label: 'Nama Wali (opsional)',
                              controller: namaWaliC,
                              hint: 'Isi jika ada wali',
                              prefixIcon: const Icon(Icons.person_outline),
                            ),
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
                  const SizedBox(height: 8),
                  // Catatan di bawah form
                  Text(
                    'Isi data wali hanya jika berbeda dengan orang tua.\n'
                    'Alamat wali dipakai untuk kontak darurat.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }
}
