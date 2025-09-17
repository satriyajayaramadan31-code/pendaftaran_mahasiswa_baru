// main.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_option.dart'; // pastikan file ini ada

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Update Dusun Wilayah',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const UploadDusunPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class UploadDusunPage extends StatefulWidget {
  const UploadDusunPage({super.key});
  @override
  State<UploadDusunPage> createState() => _UploadDusunPageState();
}

class _UploadDusunPageState extends State<UploadDusunPage> {
  String _status =
      'Tekan tombol untuk memperbarui/menambah data dusun di koleksi "wilayah".';
  bool _running = false;

  /// Data update (dusun tambahan)
  final List<Map<String, dynamic>> _records = [
    {
      'kodePos': '65151',
      'desa': 'Selorejo',
      'kecamatan': 'Dau',
      'kabupaten': 'Malang',
      'provinsi': 'Jawa Timur',
      'dusun_list': ['Selorejo', 'Brumbung', 'Darungan'],
    },
    {
      'kodePos': '65160',
      'desa': 'Sumberpucung',
      'kecamatan': 'Sumberpucung',
      'kabupaten': 'Malang',
      'provinsi': 'Jawa Timur',
      'dusun_list': ['Suko', 'Krajan', 'Mentaraman'],
    },
    {
      'kodePos': '65165',
      'desa': 'Kromengan',
      'kecamatan': 'Kromengan',
      'kabupaten': 'Malang',
      'provinsi': 'Jawa Timur',
      'dusun_list': ['Krajan', 'Cendol', 'Cendol Timur', 'Cendol Barat', 'Karangtengah'],
    },
    {
      'kodePos': '65166',
      'desa': 'Kalipare',
      'kecamatan': 'Kalipare',
      'kabupaten': 'Malang',
      'provinsi': 'Jawa Timur',
      'dusun_list': [
        'Kaliasem',
        'Kampung Ledok',
        'Kauman',
        'Krajan',
        'Ngembul',
        'Pitrang',
        'Pohjejer',
        'Sumber Klampok',
        'Sumber Kombang',
        'Sumber Maron'
      ],
    },
  ];

  Future<void> _applyUpdates() async {
    setState(() {
      _running = true;
      _status = 'Menjalankan update...';
    });

    final firestore = FirebaseFirestore.instance;
    int updated = 0;
    List<String> errors = [];

    print('=== Mulai update dusun ke koleksi "wilayah" ===');

    for (final rec in _records) {
      final kode = (rec['kodePos'] ?? '').toString();
      if (kode.isEmpty) continue;
      final docRef = firestore.collection('wilayah').doc(kode);

      try {
        final docSnap = await docRef.get();
        final List<String> newDusun = List<String>.from(rec['dusun_list'] ?? []);

        if (docSnap.exists) {
          final dataLama = docSnap.data() ?? {};
          final List<String> dusunLama =
              List<String>.from(dataLama['dusun_list'] ?? []);
          final gabungan = {...dusunLama, ...newDusun}.toList();

          await docRef.set({
            'dusun_list': gabungan,
            'desa': rec['desa'] ?? dataLama['desa'] ?? '',
            'kecamatan': rec['kecamatan'] ?? dataLama['kecamatan'] ?? '',
            'kabupaten': rec['kabupaten'] ?? dataLama['kabupaten'] ?? '',
            'provinsi': rec['provinsi'] ?? dataLama['provinsi'] ?? '',
          }, SetOptions(merge: true));

          print(
              'Updated doc $kode — desa: ${rec['desa']} — total dusun: ${gabungan.length}');
        } else {
          await docRef.set({
            'kodePos': kode,
            'desa': rec['desa'] ?? '',
            'kecamatan': rec['kecamatan'] ?? '',
            'kabupaten': rec['kabupaten'] ?? '',
            'provinsi': rec['provinsi'] ?? '',
            'dusun_list': newDusun,
          });
          print('Created doc $kode — desa: ${rec['desa']}');
        }

        updated++;
      } catch (e, st) {
        final msg = 'Gagal update $kode: $e';
        print(msg);
        print(st);
        errors.add(msg);
      }
    }

    final summary =
        'Selesai: updated/created $updated dokumen. errors=${errors.length}';
    print('=== $summary ===');

    setState(() {
      _running = false;
      _status = summary + (errors.isNotEmpty ? ' (cek console)' : '');
    });
  }

  Future<List<Map<String, dynamic>>> _fetchUploaded() async {
    final col = FirebaseFirestore.instance.collection('wilayah');
    final snap = await col.get();
    return snap.docs.map((d) {
      final m = d.data();
      m['id'] = d.id;
      return m;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perbarui Dusun - Koleksi wilayah')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(_status, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            _running
                ? const CircularProgressIndicator()
                : Column(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _applyUpdates,
                        icon: const Icon(Icons.update),
                        label: const Text('Jalankan Update'),
                        style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48)),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final list = await _fetchUploaded();
                          print(
                              '--- fetched wilayah collection (${list.length}) ---');
                          for (final e in list) {
                            print(jsonEncode(e));
                          }
                          setState(() => _status =
                              'Fetched ${list.length} dokumen (cek console)');
                        },
                        icon: const Icon(Icons.download),
                        label: const Text('Ambil & Cetak Semua'),
                        style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48)),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}
