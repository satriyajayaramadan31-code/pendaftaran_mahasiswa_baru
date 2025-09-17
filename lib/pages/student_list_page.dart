import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/student.dart';
import '../pages/student_form_wizard.dart';

class StudentListPage extends StatefulWidget {
  const StudentListPage({super.key});

  @override
  State<StudentListPage> createState() => _StudentListPageState();
}

class _StudentListPageState extends State<StudentListPage> {
  // Instance FirestoreService untuk stream/list data siswa
  final FirestoreService _fs = FirestoreService();

  // Controller untuk input pencarian
  final TextEditingController _searchC = TextEditingController();

  // Variabel untuk menyimpan query pencarian
  String _search = '';

  // Status pengurutan nama siswa (ascending/descending)
  bool _sortByNameAsc = true;

  // Cache sementara data siswa yang diambil dari Firestore
  List<Student> _cached = [];

  @override
  void dispose() {
    // Hapus controller saat widget dihapus dari tree
    _searchC.dispose();
    super.dispose();
  }

  // Fungsi untuk menerapkan filter search dan sorting pada list siswa
  List<Student> _applyFilters(List<Student> src) {
    final q = _search.trim().toLowerCase(); // Query search lowercase
    var list = src;

    // Filter berdasarkan nama, NISN, atau desa jika query tidak kosong
    if (q.isNotEmpty) {
      list = list.where((s) {
        final nama = s.nama.toLowerCase();
        final nisn = s.nisn.toLowerCase();
        final desa = s.alamat.desa.toLowerCase();
        return nama.contains(q) || nisn.contains(q) || desa.contains(q);
      }).toList();
    } else {
      list = List.from(src); // Copy list asli
    }

    // Sorting list berdasarkan nama
    list.sort((a, b) {
      final an = a.nama.toLowerCase();
      final bn = b.nama.toLowerCase();
      return _sortByNameAsc ? an.compareTo(bn) : bn.compareTo(an);
    });

    return list;
  }

  // Dialog konfirmasi sebelum menghapus data siswa
  Future<void> _confirmDelete(BuildContext ctx, Student s) async {
    final yes = await showDialog<bool>(
      context: ctx,
      builder: (dctx) => AlertDialog(
        title: const Text('Hapus data'),
        content: Text('Hapus data siswa "${s.nama}" (NISN: ${s.nisn})?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dctx).pop(false), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(dctx).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    // Jika pengguna memilih "Ya", hapus data
    if (yes == true) {
      await _deleteStudent(ctx, s);
    }
  }

  // Hapus data siswa di Firestore
  Future<void> _deleteStudent(BuildContext ctx, Student s) async {
    final snack = ScaffoldMessenger.of(ctx);
    if (s.id == null) {
      snack.showSnackBar(const SnackBar(content: Text('Gagal: id dokumen kosong')));
      return;
    }
    try {
      await FirebaseFirestore.instance.collection('students').doc(s.id).delete();
      snack.showSnackBar(const SnackBar(content: Text('Data siswa dihapus')));
    } catch (e) {
      snack.showSnackBar(SnackBar(content: Text('Gagal hapus: $e')));
    }
  }

  // Membuka bottom sheet untuk mengedit data siswa
  void _openEditSheet(BuildContext context, Student s) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom), // Hindari keyboard overlay
          child: _EditStudentForm(student: s),
        );
      },
    );
  }

  // Menampilkan detail siswa dalam bottom sheet draggable
  void _showDetailSheet(BuildContext context, Student s) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, controller) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ListView(
                  controller: controller,
                  children: [
                    // Header info + aksi edit/hapus
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.teal.shade400,
                          child: Text(
                            s.nama.isNotEmpty ? s.nama[0].toUpperCase() : '?',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.nama, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text('NISN: ${s.nisn}', style: const TextStyle(color: Colors.black54)),
                            ],
                          ),
                        ),
                        IconButton(onPressed: () { Navigator.of(ctx).pop(); _openEditSheet(context, s); }, icon: const Icon(Icons.edit, color: Colors.blue)),
                        IconButton(onPressed: () { Navigator.of(ctx).pop(); _confirmDelete(context, s); }, icon: const Icon(Icons.delete, color: Colors.red)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Kartu info identitas, kontak, alamat, orang tua/wali
                    _infoCard('Identitas', [
                      _kv('Jenis Kelamin', s.jenisKelamin),
                      _kv('Agama', s.agama),
                      _kv('Tempat Lahir', s.tempatLahir),
                      _kv('Tanggal Lahir', s.tanggalLahir != null ? s.tanggalLahir!.toLocal().toString().split(' ')[0] : '-'),
                    ]),
                    const SizedBox(height: 8),
                    _infoCard('Kontak', [
                      _kv('No HP', s.noHp),
                      _kv('NIK', s.nik),
                    ]),
                    const SizedBox(height: 8),
                    _infoCard('Alamat', [
                      _kv('Jalan', s.alamat.jalan),
                      _kv('RT/RW', s.alamat.rtRw),
                      _kv('Dusun', s.alamat.dusun),
                      _kv('Desa', s.alamat.desa),
                      _kv('Kecamatan', s.alamat.kecamatan),
                      _kv('Kabupaten', s.alamat.kabupaten),
                      _kv('Provinsi', s.alamat.provinsi),
                      _kv('Kode Pos', s.alamat.kodePos),
                    ]),
                    const SizedBox(height: 8),
                    _infoCard('Orang Tua / Wali', [
                      _kv('Nama Ayah', s.orangTuaWali.namaAyah),
                      _kv('Nama Ibu', s.orangTuaWali.namaIbu),
                      _kv('Nama Wali', s.orangTuaWali.namaWali),
                      _kv('Alamat Wali', s.orangTuaWali.alamatWali),
                    ]),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text('Dibuat: ${s.createdAt.toLocal().toString().split(' ')[0]}', style: const TextStyle(color: Colors.black54, fontSize: 12)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Helper untuk key-value display
  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            SizedBox(width: 120, child: Text(k, style: const TextStyle(fontWeight: FontWeight.w600))),
            Expanded(child: Text(v)),
          ],
        ),
      );

  // Helper untuk membuat card info
  Widget _infoCard(String title, List<Widget> children) {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 6),
          ...children,
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(Icons.school_outlined),
            SizedBox(width: 8),
            Text('Daftar Siswa'),
          ],
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF00796B), Color(0xFF26A69A)]),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Refresh list siswa
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Merefresh...')));
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        onPressed: () async {
          // Navigasi ke halaman tambah siswa
          final res = await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StudentFormWizardPage()));
          if (res == true && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data siswa berhasil ditambahkan.')));
          }
        },
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search + Sort section
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))
                      ]),
                      child: TextField(
                        controller: _searchC,
                        onChanged: (v) => setState(() => _search = v), // Update query search
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          hintText: 'Cari nama / NISN / desa ...',
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                          suffixIcon: _search.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchC.clear();
                                    setState(() => _search = '');
                                  },
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Button untuk toggle sorting
                  Tooltip(
                    message: 'Urutkan nama',
                    child: InkWell(
                      onTap: () => setState(() => _sortByNameAsc = !_sortByNameAsc),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))
                        ]),
                        child: Row(
                          children: [
                            Icon(_sortByNameAsc ? Icons.sort_by_alpha : Icons.sort_by_alpha_outlined, color: Colors.teal),
                            const SizedBox(width: 4),
                            Icon(_sortByNameAsc ? Icons.arrow_upward : Icons.arrow_downward, size: 14, color: Colors.teal),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // List siswa
            Expanded(
              child: StreamBuilder<List<Student>>(
                stream: _fs.studentsStream(), // Stream data siswa
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator()); // Loading indicator
                  }
                  if (snap.hasError) {
                    return Center(child: Text('Terjadi kesalahan: ${snap.error}')); // Error
                  }

                  final raw = snap.data ?? [];
                  _cached = raw; // Update cache

                  final list = _applyFilters(raw); // Apply search & sort

                  if (list.isEmpty) {
                    // Tampilan kosong jika tidak ada siswa
                    return RefreshIndicator(
                      onRefresh: () async => setState(() {}),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 80),
                          Icon(Icons.people_outline, size: 84, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          const Center(child: Text('Belum ada siswa terdaftar', style: TextStyle(fontSize: 18, color: Colors.black54))),
                          const SizedBox(height: 8),
                          const Center(child: Text('Tekan tombol + untuk menambah data baru', style: TextStyle(color: Colors.black45))),
                        ],
                      ),
                    );
                  }

                  // List siswa dengan RefreshIndicator
                  return RefreshIndicator(
                    onRefresh: () async => setState(() {}),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      itemCount: list.length,
                      itemBuilder: (context, idx) {
                        final s = list[idx];
                        return _StudentCardModern(
                          student: s,
                          onView: () => _showDetailSheet(context, s),
                          onEdit: () => _openEditSheet(context, s),
                          onDelete: () => _confirmDelete(context, s),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Card modern untuk menampilkan info siswa
class _StudentCardModern extends StatelessWidget {
  final Student student;
  final VoidCallback onView, onEdit, onDelete;

  const _StudentCardModern({required this.student, required this.onView, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final born = student.tanggalLahir != null ? student.tanggalLahir!.toLocal().toString().split(' ')[0] : '-';
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onView, // Tap card untuk view detail
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar dengan huruf awal nama siswa
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF26A69A), Color(0xFF00796B)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(student.nama.isNotEmpty ? student.nama[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(student.nama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                    Text(born, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                  ]),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Chip(label: Text('NISN: ${student.nisn}'), visualDensity: VisualDensity.compact),
                      if (student.alamat.desa.isNotEmpty) Chip(label: Text(student.alamat.desa), visualDensity: VisualDensity.compact),
                    ],
                  ),
                ]),
              ),
              // Menu aksi: Lihat / Ubah / Hapus
              PopupMenuButton<int>(
                onSelected: (v) {
                  if (v == 0) onView();
                  if (v == 1) onEdit();
                  if (v == 2) onDelete();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 0, child: ListTile(leading: Icon(Icons.visibility), title: Text('Lihat'))),
                  const PopupMenuItem(value: 1, child: ListTile(leading: Icon(Icons.edit), title: Text('Ubah'))),
                  const PopupMenuItem(value: 2, child: ListTile(leading: Icon(Icons.delete, color: Colors.red), title: Text('Hapus'))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Form untuk edit data siswa
class _EditStudentForm extends StatefulWidget {
  final Student student;
  const _EditStudentForm({required this.student});

  @override
  State<_EditStudentForm> createState() => _EditStudentFormState();
}

class _EditStudentFormState extends State<_EditStudentForm> {
  final _formKey = GlobalKey<FormState>();

  // Controllers untuk field form
  late final TextEditingController nisnC;
  late final TextEditingController namaC;
  late final TextEditingController jenisKelaminC;
  late final TextEditingController agamaC;
  late final TextEditingController tempatC;
  DateTime? tanggalLahir;
  late final TextEditingController nomorHpC;
  late final TextEditingController nikC;

  // Controllers alamat
  late final TextEditingController jalanC;
  late final TextEditingController rtRwC;
  late final TextEditingController dusunC;
  late final TextEditingController desaC;
  late final TextEditingController kecamatanC;
  late final TextEditingController kabupatenC;
  late final TextEditingController provinsiC;
  late final TextEditingController kodePosC;

  // Controllers orang tua / wali
  late final TextEditingController namaAyahC;
  late final TextEditingController namaIbuC;
  late final TextEditingController namaWaliC;
  late final TextEditingController alamatWaliC;

  // Flag saat menyimpan perubahan
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.student;

    // Inisialisasi controller dengan data siswa
    nisnC = TextEditingController(text: s.nisn);
    namaC = TextEditingController(text: s.nama);
    jenisKelaminC = TextEditingController(text: s.jenisKelamin);
    agamaC = TextEditingController(text: s.agama);
    tempatC = TextEditingController(text: s.tempatLahir);
    tanggalLahir = s.tanggalLahir;
    nomorHpC = TextEditingController(text: s.noHp);
    nikC = TextEditingController(text: s.nik);

    jalanC = TextEditingController(text: s.alamat.jalan);
    rtRwC = TextEditingController(text: s.alamat.rtRw);
    dusunC = TextEditingController(text: s.alamat.dusun);
    desaC = TextEditingController(text: s.alamat.desa);
    kecamatanC = TextEditingController(text: s.alamat.kecamatan);
    kabupatenC = TextEditingController(text: s.alamat.kabupaten);
    provinsiC = TextEditingController(text: s.alamat.provinsi);
    kodePosC = TextEditingController(text: s.alamat.kodePos);

    namaAyahC = TextEditingController(text: s.orangTuaWali.namaAyah);
    namaIbuC = TextEditingController(text: s.orangTuaWali.namaIbu);
    namaWaliC = TextEditingController(text: s.orangTuaWali.namaWali);
    alamatWaliC = TextEditingController(text: s.orangTuaWali.alamatWali);
  }

  @override
  void dispose() {
    // Dispose semua controller
    nisnC.dispose();
    namaC.dispose();
    jenisKelaminC.dispose();
    agamaC.dispose();
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

  // Pick tanggal lahir dengan date picker
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(context: context, initialDate: tanggalLahir ?? DateTime(now.year - 10), firstDate: DateTime(1900), lastDate: now);
    if (picked != null) setState(() => tanggalLahir = picked);
  }

  // Simpan perubahan edit ke Firestore
  Future<void> _saveEdits() async {
    if (!_formKey.currentState!.validate()) return; // Validasi form
    if (widget.student.id == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ID dokumen kosong')));
      return;
    }
    setState(() => _saving = true);

    // Payload data siswa
    final payload = {
      'nisn': nisnC.text.trim(),
      'nama': namaC.text.trim(),
      'jenisKelamin': jenisKelaminC.text.trim(),
      'agama': agamaC.text.trim(),
      'tempatLahir': tempatC.text.trim(),
      'tanggalLahir': tanggalLahir != null ? Timestamp.fromDate(tanggalLahir!) : null,
      'noHp': nomorHpC.text.trim(),
      'nik': nikC.text.trim(),
      'alamat': {
        'jalan': jalanC.text.trim(),
        'rtRw': rtRwC.text.trim(),
        'dusun': dusunC.text.trim(),
        'desa': desaC.text.trim(),
        'kecamatan': kecamatanC.text.trim(),
        'kabupaten': kabupatenC.text.trim(),
        'provinsi': provinsiC.text.trim(),
        'kodePos': kodePosC.text.trim(),
      },
      'orangTuaWali': {
        'namaAyah': namaAyahC.text.trim(),
        'namaIbu': namaIbuC.text.trim(),
        'namaWali': namaWaliC.text.trim(),
        'alamatWali': alamatWaliC.text.trim(),
      },
      'updatedAt': Timestamp.now(),
    };

    try {
      await FirebaseFirestore.instance.collection('students').doc(widget.student.id).set(payload, SetOptions(merge: true));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perubahan tersimpan')));
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // Field input kecil (helper)
  Widget _smallField(TextEditingController c, String label, {TextInputType? t}) {
    return TextFormField(
      controller: c,
      keyboardType: t,
      decoration: InputDecoration(labelText: label, isDense: true, border: const OutlineInputBorder()),
      validator: (v) => (label == 'Nama' && (v == null || v.trim().isEmpty)) ? 'Nama wajib' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            controller: controller,
            children: [
              // Header form
              Row(
                children: [
                  const Expanded(child: Text('Ubah Data Siswa', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                  IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 8),
              Form(
                key: _formKey,
                child: Column(children: [
                  _smallField(namaC, 'Nama'),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: _smallField(nisnC, 'NISN', t: TextInputType.number)),
                    const SizedBox(width: 8),
                    Expanded(child: _smallField(jenisKelaminC, 'Jenis Kelamin')),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: _smallField(agamaC, 'Agama')),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: _pickDate,
                        child: IgnorePointer(
                          child: TextFormField(
                            decoration: InputDecoration(labelText: 'Tanggal Lahir', isDense: true, hintText: tanggalLahir != null ? tanggalLahir!.toLocal().toString().split(' ')[0] : 'Pilih tanggal'),
                          ),
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  _smallField(nomorHpC, 'No HP', t: TextInputType.phone),
                  const SizedBox(height: 8),
                  _smallField(nikC, 'NIK', t: TextInputType.number),
                  const SizedBox(height: 12),
                  const Divider(),
                  const Align(alignment: Alignment.centerLeft, child: Text('Alamat', style: TextStyle(fontWeight: FontWeight.bold))),
                  const SizedBox(height: 8),
                  _smallField(jalanC, 'Jalan / Nama Jalan'),
                  const SizedBox(height: 8),
                  Row(children: [Expanded(child: _smallField(rtRwC, 'RT / RW')), const SizedBox(width: 8), Expanded(child: _smallField(kodePosC, 'Kode Pos'))]),
                  const SizedBox(height: 8),
                  Row(children: [Expanded(child: _smallField(dusunC, 'Dusun')), const SizedBox(width: 8), Expanded(child: _smallField(desaC, 'Desa / Kelurahan'))]),
                  const SizedBox(height: 8),
                  Row(children: [Expanded(child: _smallField(kecamatanC, 'Kecamatan')), const SizedBox(width: 8), Expanded(child: _smallField(kabupatenC, 'Kabupaten / Kota'))]),
                  const SizedBox(height: 8),
                  _smallField(provinsiC, 'Provinsi'),
                  const SizedBox(height: 12),
                  const Divider(),
                  const Align(alignment: Alignment.centerLeft, child: Text('Orang Tua / Wali', style: TextStyle(fontWeight: FontWeight.bold))),
                  const SizedBox(height: 8),
                  _smallField(namaAyahC, 'Nama Ayah'),
                  const SizedBox(height: 8),
                  _smallField(namaIbuC, 'Nama Ibu'),
                  const SizedBox(height: 8),
                  _smallField(namaWaliC, 'Nama Wali'),
                  const SizedBox(height: 8),
                  _smallField(alamatWaliC, 'Alamat Wali'),
                  const SizedBox(height: 16),
                  // Tombol aksi simpan/batal
                  _saving ? const CircularProgressIndicator() : Row(children: [
                    Expanded(child: OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Batal'))),
                    const SizedBox(width: 12),
                    Expanded(child: ElevatedButton(onPressed: _saveEdits, child: const Text('Simpan Perubahan'))),
                  ]),
                ]),
              )
            ],
          ),
        ),
      ),
    );
  }
}
