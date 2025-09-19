import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';

import '../services/firestore_service.dart';
import '../models/student.dart';
import '../pages/student_form_wizard.dart';

/// Halaman utama daftar siswa.
/// Catatan: Saya hanya menambahkan komentar. Tidak mengubah fungsi apapun.
class StudentListPage extends StatefulWidget {
  const StudentListPage({super.key});

  @override
  State<StudentListPage> createState() => _StudentListPageState();
}

class _StudentListPageState extends State<StudentListPage> {
  // FirestoreService: abstraksi stream / CRUD untuk koleksi students.
  final FirestoreService _fs = FirestoreService();

  // Controller untuk input pencarian.
  final TextEditingController _searchC = TextEditingController();

  // Variabel pencarian (nilai yang dipakai _applyFilters).
  String _search = '';

  // Toggle sort by name: true = ascending, false = descending.
  bool _sortByNameAsc = true; // toggle 1 tombol saja (ascending/descending)

  // Cache terakhir dari stream agar bisa digunakan / disimpan di memori jika perlu.
  List<Student> _cached = [];

  // Connectivity handling:
  // - _isOffline: jika true => tampil banner offline dan ubah teks koneksi
  // - _connTypeLabel: label untuk tampilan (misal "Tersambung" atau '—')
  bool _isOffline = false;
  String _connTypeLabel = '—';
  StreamSubscription<dynamic>? _connectivitySub;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    // Mulai memonitor konektivitas saat halaman diinisialisasi.
    _startConnectivityMonitor();
  }

  @override
  void dispose() {
    // Bersihkan semua controller / subscription / timer saat widget di-destroy.
    _searchC.dispose();
    _connectivitySub?.cancel();
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// Normalisasi event konektivitas.
  /// connectivity_plus bisa mengembalikan ConnectivityResult ataupun List<ConnectivityResult>
  /// tergantung platform / versi, sehingga helper ini memastikan kita selalu dapat ConnectivityResult.
  ConnectivityResult _normalizeConnectivity(dynamic event) {
    if (event is ConnectivityResult) return event;
    if (event is List<ConnectivityResult>) {
      // jika ada list, ambil yang pertama; jika kosong, return none.
      return event.isNotEmpty ? event.first : ConnectivityResult.none;
    }
    return ConnectivityResult.none;
  }

  /// Mulai pemantauan konektivitas:
  /// - cek awal (_checkAndUpdateConnectivity)
  /// - dengarkan onConnectivityChanged, dengan debounce kecil agar UI tidak berkedip
  /// - jika ada error pada stream, jalankan fallback untuk cek ulang setelah delay
  void _startConnectivityMonitor() {
    _checkAndUpdateConnectivity();
    _connectivitySub = Connectivity().onConnectivityChanged.listen((event) {
      final normalized = _normalizeConnectivity(event);
      // batalkan timer sebelumnya, lalu set debounce 250ms
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 250), () {
        _onConnectivityChanged(normalized);
      });
    }, onError: (_) {
      // Jika ada error, coba cek ulang setelah sedikit delay.
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 300), _checkAndUpdateConnectivity);
    });
  }

  // Simpler: jika ada interface selain none => online. Hanya none => offline.
  // Mengubah state `_isOffline` dan `_connTypeLabel` sesuai hasil.
  Future<void> _onConnectivityChanged(ConnectivityResult result) async {
    if (!mounted) return;
    if (result == ConnectivityResult.none) {
      setState(() {
        _isOffline = true;
        _connTypeLabel = '—';
      });
    } else {
      setState(() {
        _isOffline = false;
        _connTypeLabel = 'Tersambung';
      });
    }
  }

  // Cek konektivitas secara manual (dipanggil pada inisialisasi dan saat user tekan refresh)
  Future<void> _checkAndUpdateConnectivity() async {
    try {
      final raw = await Connectivity().checkConnectivity();
      final conn = _normalizeConnectivity(raw);
      await _onConnectivityChanged(conn);
    } catch (_) {
      // Jika gagal cek, anggap offline (safest).
      if (mounted) setState(() => _isOffline = true);
    }
  }

  /// Terapkan filter pencarian dan pengurutan.
  /// - Mencocokkan nama, nisn, atau desa (case-insensitive)
  /// - Mengembalikan list baru yang sudah diurutkan sesuai `_sortByNameAsc`
  List<Student> _applyFilters(List<Student> src) {
    final q = _search.trim().toLowerCase();
    var list = src;
    if (q.isNotEmpty) {
      // Filter berdasarkan nama / nisn / desa
      list = list.where((s) {
        final nama = s.nama.toLowerCase();
        final nisn = s.nisn.toLowerCase();
        final desa = s.alamat.desa.toLowerCase();
        return nama.contains(q) || nisn.contains(q) || desa.contains(q);
      }).toList();
    } else {
      // jika query kosong, clone list asli agar tidak merusak sumber
      list = List.from(src);
    }

    // Sorting berdasarkan nama (case-insensitive)
    list.sort((a, b) {
      final an = a.nama.toLowerCase();
      final bn = b.nama.toLowerCase();
      return _sortByNameAsc ? an.compareTo(bn) : bn.compareTo(an);
    });
    return list;
  }

  /// Tampilkan dialog konfirmasi sebelum hapus.
  /// Jika user memilih 'Hapus', akan memanggil _deleteStudent.
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

    if (yes == true) {
      await _deleteStudent(ctx, s);
    }
  }

  /// Hapus dokumen siswa dari Firestore.
  /// - Menangani kasus id null
  /// - Menampilkan SnackBar hasil (sukses / gagal)
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

  /// Buka bottom sheet untuk mengedit data siswa.
  /// Menggunakan widget _EditStudentForm yang ada di bagian bawah file.
  void _openEditSheet(BuildContext context, Student s) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: _EditStudentForm(student: s),
        );
      },
    );
  }

  /// Menampilkan detail siswa dalam DraggableScrollableSheet (mirip sheet yang bisa di-drag naik/turun).
  /// Di dalamnya ditampilkan kartu identitas, kontak, alamat, orang tua, dan tanggal dibuat.
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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar inisial nama
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
                              // Nama + NISN
                              Text(s.nama, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text('NISN: ${s.nisn}', style: const TextStyle(color: Colors.black54)),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            // Tombol edit / hapus di header detail (memanggil fungsi terkait)
                            IconButton(onPressed: () { Navigator.of(ctx).pop(); _openEditSheet(context, s); }, icon: const Icon(Icons.edit, color: Colors.blue)),
                            IconButton(onPressed: () { Navigator.of(ctx).pop(); _confirmDelete(context, s); }, icon: const Icon(Icons.delete, color: Colors.red)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Kartu-kartu informasi (gunakan helper _infoCard dan _kv)
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
                    // Tanggal pembuatan (createdAt)
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

  /// Helper: key-value row untuk menampilkan field pada detail.
  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            // Label fixed width supaya rapi
            SizedBox(width: 120, child: Text(k, style: const TextStyle(fontWeight: FontWeight.w600))),
            Expanded(child: Text(v)),
          ],
        ),
      );

  /// Helper: membungkus beberapa _kv ke dalam Card dengan judul.
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
    // Primary gradient untuk AppBar
    final primaryGradient = const LinearGradient(colors: [Color(0xFF00796B), Color(0xFF26A69A)]);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.school_outlined),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Daftar Siswa',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 8),
            // Jika online, tampilkan badge kecil di AppBar (connTypeLabel)
            if (!_isOffline)
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 120),
                child: Container(
                  margin: const EdgeInsets.only(left: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade600,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi, size: 14, color: Colors.white),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          _connTypeLabel,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        centerTitle: false,
        elevation: 0,
        flexibleSpace: Container(decoration: BoxDecoration(gradient: primaryGradient)),
        actions: [
          // Tombol refresh untuk manual cek koneksi + beri feedback cepat via SnackBar
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _checkAndUpdateConnectivity();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Merefresh...')));
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        elevation: 6,
        // Navigasi ke halaman tambah siswa (StudentFormWizardPage)
        onPressed: () async {
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
            // Jika offline, tampilkan banner merah di atas konten.
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _isOffline
                  ? Container(
                      key: const ValueKey('offline_banner'),
                      width: double.infinity,
                      color: Colors.red.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.wifi_off, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text('Tidak ada koneksi internet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            // Search bar + tombol toggle sort
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Expanded(
                    child: Material(
                      elevation: 3,
                      borderRadius: BorderRadius.circular(12),
                      child: TextField(
                        controller: _searchC,
                        // Langsung set state saat teks berubah (dipakai untuk filter)
                        onChanged: (v) => setState(() => _search = v),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          hintText: 'Cari nama / NISN / desa ...',
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          // Tombol clear muncul jika ada teks
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
                  Container(
                    // Ikon sort yang hanya toggle ascending/descending
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))
                    ]),
                    child: IconButton(
                      tooltip: 'Toggle sort',
                      icon: Icon(_sortByNameAsc ? Icons.sort_by_alpha : Icons.sort_by_alpha_outlined, color: Colors.teal),
                      onPressed: () => setState(() => _sortByNameAsc = !_sortByNameAsc),
                    ),
                  ),
                ],
              ),
            ),

            // List siswa: menggunakan StreamBuilder dari firestore service
            Expanded(
              child: StreamBuilder<List<Student>>(
                stream: _fs.studentsStream(),
                builder: (context, snap) {
                  // Tampilkan loading jika stream masih menunggu data
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    // Jika error, tampilkan pesan error
                    return Center(child: Text('Terjadi kesalahan: ${snap.error}'));
                  }

                  final raw = snap.data ?? [];
                  // Simpan ke cache lokal (dipakai jika ingin referensi cepat)
                  _cached = raw;
                  // Terapkan filter pencarian dan sort
                  final list = _applyFilters(raw);

                  if (list.isEmpty) {
                    // Jika kosong, tampilkan UI kosong + hint
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

                  // Jika ada data, tampilkan ListView dengan RefreshIndicator.
                  // Setiap item diberi animasi SlideInUp (staggered ringan)
                  return RefreshIndicator(
                    onRefresh: () async => setState(() {}),
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, idx) {
                        final s = list[idx];
                        // use a subtle SlideInUp animation per item (staggered)
                        return SlideInUp(
                          duration: Duration(milliseconds: 350 + (idx % 6) * 40),
                          child: Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                            child: ListTile(
                              // Ketuk item membuka detail sheet
                              onTap: () => _showDetailSheet(context, s),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              leading: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [Color(0xFF26A69A), Color(0xFF00796B)]),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(s.nama.isNotEmpty ? s.nama[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(child: Text(s.nama, style: const TextStyle(fontWeight: FontWeight.bold))),
                                  // Tanggal lahir di ujung kanan (format yyyy-mm-dd jika ada)
                                  Text(s.tanggalLahir != null ? s.tanggalLahir!.toLocal().toString().split(' ')[0] : '-', style: const TextStyle(color: Colors.black54, fontSize: 12)),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 6.0),
                                child: Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    // Chip untuk NISN dan desa (jika ada)
                                    Chip(label: Text('NISN: ${s.nisn}'), visualDensity: VisualDensity.compact, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
                                    if (s.alamat.desa.isNotEmpty) Chip(label: Text(s.alamat.desa), visualDensity: VisualDensity.compact, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
                                  ],
                                ),
                              ),
                              trailing: PopupMenuButton<int>(
                                onSelected: (v) {
                                  // Menu tindakan cepat: Lihat, Ubah, Hapus
                                  if (v == 0) _showDetailSheet(context, s);
                                  if (v == 1) _openEditSheet(context, s);
                                  if (v == 2) _confirmDelete(context, s);
                                },
                                itemBuilder: (_) => [
                                  const PopupMenuItem(value: 0, child: ListTile(leading: Icon(Icons.visibility), title: Text('Lihat'))),
                                  const PopupMenuItem(value: 1, child: ListTile(leading: Icon(Icons.edit), title: Text('Ubah'))),
                                  const PopupMenuItem(value: 2, child: ListTile(leading: Icon(Icons.delete, color: Colors.red), title: Text('Hapus'))),
                                ],
                              ),
                            ),
                          ),
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

/// (Edit form code kept unchanged below...)
/// Widget form edit siswa yang muncul di bottom sheet.
/// Semua logika validasi & penyimpanan tetap sama; hanya komentar yang ditambahkan.
class _EditStudentForm extends StatefulWidget {
  final Student student;
  const _EditStudentForm({required this.student});

  @override
  State<_EditStudentForm> createState() => _EditStudentFormState();
}

class _EditStudentFormState extends State<_EditStudentForm> {
  final _formKey = GlobalKey<FormState>();

  // Controllers untuk masing-masing field form
  late final TextEditingController nisnC;
  late final TextEditingController namaC;
  late final TextEditingController jenisKelaminC;
  late final TextEditingController agamaC;
  late final TextEditingController tempatC;
  DateTime? tanggalLahir;
  late final TextEditingController nomorHpC;
  late final TextEditingController nikC;

  late final TextEditingController jalanC;
  late final TextEditingController rtRwC;
  late final TextEditingController dusunC;
  late final TextEditingController desaC;
  late final TextEditingController kecamatanC;
  late final TextEditingController kabupatenC;
  late final TextEditingController provinsiC;
  late final TextEditingController kodePosC;

  late final TextEditingController namaAyahC;
  late final TextEditingController namaIbuC;
  late final TextEditingController namaWaliC;
  late final TextEditingController alamatWaliC;

  // Flag loading saat menyimpan perubahan
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.student;

    // Inisialisasi controller dengan nilai existing dari student
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
    // Dispose semua controller untuk mencegah memory leak
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

  /// Picker tanggal lahir menggunakan showDatePicker.
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(context: context, initialDate: tanggalLahir ?? DateTime(now.year - 10), firstDate: DateTime(1900), lastDate: now);
    if (picked != null) setState(() => tanggalLahir = picked);
  }

  /// Simpan perubahan ke Firestore menggunakan .set(..., SetOptions(merge: true))
  /// - Validasi form terlebih dahulu
  /// - Buat payload map sesuai struktur dokumen
  /// - Tampilkan SnackBar hasil operasi
  Future<void> _saveEdits() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.student.id == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ID dokumen kosong')));
      return;
    }
    setState(() => _saving = true);

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
      // updatedAt untuk tracking perubahan
      'updatedAt': Timestamp.now(),
    };

    try {
      // Merge true agar tidak menimpa field lain yang tidak dikirim.
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

  // Helper: field kecil berulang yang dipakai di banyak tempat di form.
  Widget _smallField(TextEditingController c, String label, {TextInputType? t}) {
    return TextFormField(
      controller: c,
      keyboardType: t,
      decoration: InputDecoration(labelText: label, isDense: true, border: const OutlineInputBorder()),
      // Validator sederhana: hanya memaksa Nama wajib
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
                      // Field tanggal lahir: gunakan InkWell + IgnorePointer agar tap membuka date picker
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
                  // Tombol Batal / Simpan: tampilkan CircularProgress saat _saving true
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
