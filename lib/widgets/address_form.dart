import 'package:flutter/material.dart';

class AddressForm extends StatelessWidget {
  const AddressForm({
    super.key,
    required this.jalanC,
    required this.rtRwC,
    required this.dusunC,
    required this.desaC,
    required this.kecamatanC,
    required this.kabupatenC,
    required this.provinsiC,
    required this.kodePosC,
  });

  final TextEditingController jalanC;
  final TextEditingController rtRwC;
  final TextEditingController dusunC;
  final TextEditingController desaC;
  final TextEditingController kecamatanC;
  final TextEditingController kabupatenC;
  final TextEditingController provinsiC;
  final TextEditingController kodePosC;

  Widget _field({
    required String label,
    required TextEditingController controller,
    String? hint,
    Widget? prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
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
    // small helper for subtle label style
    final sectionTitleStyle = TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[800]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Alamat Lengkap', style: sectionTitleStyle),
        const SizedBox(height: 8),

        // Jalan (full width)
        _field(
          label: 'Jalan / Nama Jalan',
          controller: jalanC,
          hint: 'Jl. Contoh No. 12 / Perumahan ...',
          prefixIcon: const Icon(Icons.streetview),
        ),

        // RT/RW & Dusun
        Row(
          children: [
            Expanded(
              child: _field(
                label: 'RT / RW',
                controller: rtRwC,
                hint: '001/002',
                prefixIcon: const Icon(Icons.format_list_numbered),
                keyboardType: TextInputType.text,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _field(
                label: 'Dusun',
                controller: dusunC,
                hint: 'Nama dusun',
                prefixIcon: const Icon(Icons.map),
              ),
            ),
          ],
        ),

        // Desa & Kecamatan
        Row(
          children: [
            Expanded(
              child: _field(
                label: 'Desa / Kelurahan',
                controller: desaC,
                hint: 'Desa contoh',
                prefixIcon: const Icon(Icons.location_city),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _field(
                label: 'Kecamatan',
                controller: kecamatanC,
                hint: 'Kecamatan contoh',
                prefixIcon: const Icon(Icons.place),
              ),
            ),
          ],
        ),

        // Kabupaten & Provinsi
        Row(
          children: [
            Expanded(
              child: _field(
                label: 'Kabupaten / Kota',
                controller: kabupatenC,
                hint: 'Kabupaten contoh',
                prefixIcon: const Icon(Icons.location_on),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _field(
                label: 'Provinsi',
                controller: provinsiC,
                hint: 'Provinsi contoh',
                prefixIcon: const Icon(Icons.flag),
              ),
            ),
          ],
        ),

        // Kode Pos & optional helper
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _field(
                label: 'Kode Pos',
                controller: kodePosC,
                hint: 'Contoh: 40234',
                prefixIcon: const Icon(Icons.mail_outline),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: ElevatedButton.icon(
                  onPressed: () {
                    // placeholder: kalau mau tambahkan fitur lookup kode pos
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Fitur pencarian kode pos belum diaktifkan.')),
                    );
                  },
                  icon: const Icon(Icons.search),
                  label: const Text('Cari Kode Pos (opsional)'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 6),
        Text(
          'Tip: Isi alamat selengkap mungkin agar surat/kontak dapat dikirim dengan benar.',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }
}
