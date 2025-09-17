import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Address form with improved UI (filled inputs, rounded borders) and required validators.
/// Functionality (wilayah cache, kodepos search, autofill) unchanged.
class AddressForm extends StatefulWidget {
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

  // Controller untuk setiap field alamat
  final TextEditingController jalanC;
  final TextEditingController rtRwC;
  final TextEditingController dusunC;
  final TextEditingController desaC;
  final TextEditingController kecamatanC;
  final TextEditingController kabupatenC;
  final TextEditingController provinsiC;
  final TextEditingController kodePosC;

  @override
  State<AddressForm> createState() => _AddressFormState();
}

class _AddressFormState extends State<AddressForm> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Cache lokal untuk autocomplete agar tidak selalu query ke Firestore
  final Set<String> _desaSet = {};
  final Set<String> _dusunSet = {};
  final Set<String> _kecamatanSet = {};
  final Set<String> _kabupatenSet = {};
  final Set<String> _provinsiSet = {};

  bool _loadingWilayah = true; // Flag loading saat fetch cache
  String? _wilayahError; // Menyimpan error jika gagal fetch

  @override
  void initState() {
    super.initState();
    // Ambil cache wilayah saat widget diinisialisasi
    _fetchWilayahCache();
  }

  /// Fetch cache wilayah dari Firestore
  /// Memasukkan data desa, dusun, kecamatan, kabupaten, provinsi
  Future<void> _fetchWilayahCache() async {
    setState(() {
      _loadingWilayah = true;
      _wilayahError = null;
    });
    try {
      final snap = await _db.collection('wilayah').get();
      for (final doc in snap.docs) {
        final m = doc.data();

        // Tambahkan nama desa (single field)
        final desa = (m['desa'] ?? '').toString().trim();
        if (desa.isNotEmpty) _desaSet.add(desa);

        // Tambahkan array desa jika ada (desa_list)
        final dynamic desaListField = m['desa_list'];
        if (desaListField is List) {
          for (final d in desaListField) {
            final s = d?.toString().trim() ?? '';
            if (s.isNotEmpty) _desaSet.add(s);
          }
        }

        // Kecamatan
        final kec = (m['kecamatan'] ?? '').toString().trim();
        if (kec.isNotEmpty) _kecamatanSet.add(kec);

        // Kabupaten / regency
        final kab = (m['kabupaten'] ?? m['regency'] ?? '').toString().trim();
        if (kab.isNotEmpty) _kabupatenSet.add(kab);

        // Provinsi
        final prov = (m['provinsi'] ?? m['province'] ?? '').toString().trim();
        if (prov.isNotEmpty) _provinsiSet.add(prov);

        // Dusun (bisa array atau string)
        final dynamic dusunField = m['dusun_list'] ?? m['dusun'];
        if (dusunField is List) {
          for (final d in dusunField) {
            final s = d?.toString().trim() ?? '';
            if (s.isNotEmpty) _dusunSet.add(s);
          }
        } else if (dusunField is String) {
          final parts = dusunField.split(',').map((e) => e.trim());
          for (final p in parts) {
            if (p.isNotEmpty) _dusunSet.add(p);
          }
        }
      }
      print(
          'Loaded wilayah cache: desa:${_desaSet.length}, dusun:${_dusunSet.length}, kec:${_kecamatanSet.length}, kab:${_kabupatenSet.length}, prov:${_provinsiSet.length}');
    } catch (e, st) {
      print('Failed load wilayah cache: $e\n$st');
      _wilayahError = 'Gagal memuat data wilayah: $e';
    } finally {
      if (mounted) setState(() => _loadingWilayah = false);
    }
  }

  // -------------------------
  // UI helpers & validators
  // -------------------------

  /// Dekorasi input field dengan border, warna latar, icon, dsb
  InputDecoration _inputDecoration({
    required String label,
    String? hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.grey.shade100,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.teal, width: 2),
      ),
      errorMaxLines: 2,
    );
  }

  /// Validator untuk field wajib diisi
  String? _requiredValidator(String? v, {String? fieldName}) {
    if (v == null || v.trim().isEmpty) return '${fieldName ?? 'Field'} wajib diisi';
    return null;
  }

  /// Build field input dengan validator wajib
  Widget _buildField({
    required String label,
    required TextEditingController controller,
    String? hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: (v) => _requiredValidator(v, fieldName: label),
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: _inputDecoration(label: label, hint: hint, prefixIcon: prefixIcon, suffixIcon: suffixIcon),
      ),
    );
  }

  // -------------------------
  // Postal code API (kodepos.vercel.app)
  // -------------------------

  /// Search kode pos via API (returns list of maps)
  Future<List<Map<String, String>>> _searchPostal(String query, {String country = 'ID'}) async {
    final results = <Map<String, String>>[];
    if (country.toUpperCase() == 'ID') {
      try {
        final uri = Uri.parse('https://kodepos.vercel.app/search/?q=${Uri.encodeComponent(query)}');
        final res = await http.get(uri).timeout(const Duration(seconds: 8));
        if (res.statusCode == 200) {
          final body = jsonDecode(res.body) as Map<String, dynamic>;
          final rawList = body['data'] as List? ?? [];
          for (final item in rawList) {
            results.add({
              'postcode': item['code']?.toString() ?? '',
              'desa': item['village']?.toString() ?? '',
              'kecamatan': item['district']?.toString() ?? '',
              'kabupaten': item['regency']?.toString() ?? (item['city']?.toString() ?? ''),
              'provinsi': item['province']?.toString() ?? '',
              'dusun': item['urban']?.toString() ?? '',
            });
          }
        } else {
          print('kodepos API status: ${res.statusCode}');
        }
      } catch (e) {
        print('kodepos API error: $e');
      }
    }
    return results;
  }

  /// Show modal bottom sheet untuk search kode pos
  Future<void> _showPostalSearchModal(BuildContext context) async {
    String country = 'ID';
    final searchController = TextEditingController();
    List<Map<String, String>> items = [];
    bool loading = false;
    String? error;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          // Fungsi pencarian kode pos ketika user submit / tekan tombol
          Future<void> doSearch() async {
            final q = searchController.text.trim();
            if (q.isEmpty) {
              setState(() => error = 'Masukkan kode pos atau nama tempat');
              return;
            }
            setState(() {
              loading = true;
              error = null;
              items = [];
            });
            try {
              final r = await _searchPostal(q, country: country);
              setState(() {
                items = r;
                if (r.isEmpty) error = 'Tidak ditemukan hasil untuk "$q"';
              });
            } catch (e) {
              setState(() => error = 'Terjadi kesalahan: $e');
            } finally {
              setState(() => loading = false);
            }
          }

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: SizedBox(
              height: MediaQuery.of(ctx).size.height * 0.6,
              child: Column(
                children: [
                  // Input pencarian dan dropdown negara
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: searchController,
                            textInputAction: TextInputAction.search,
                            onSubmitted: (_) => doSearch(),
                            decoration: const InputDecoration(
                              labelText: 'Cari kode pos / nama tempat',
                              prefixIcon: Icon(Icons.search),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        DropdownButton<String>(
                          value: country,
                          items: const [
                            DropdownMenuItem(value: 'ID', child: Text('ID')),
                            DropdownMenuItem(value: 'US', child: Text('US')),
                            DropdownMenuItem(value: 'GB', child: Text('GB')),
                            DropdownMenuItem(value: 'DE', child: Text('DE')),
                          ],
                          onChanged: (v) => setState(() => country = v ?? 'ID'),
                        ),
                      ],
                    ),
                  ),
                  if (loading) const LinearProgressIndicator(),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(error!, style: const TextStyle(color: Colors.red)),
                    ),
                  // List hasil pencarian
                  Expanded(
                    child: items.isEmpty
                        ? Center(child: Text(loading ? 'Mencari...' : 'Tidak ada hasil.'))
                        : ListView.separated(
                            itemCount: items.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final it = items[index];
                              return ListTile(
                                title: Text('${it['desa'] ?? it['dusun'] ?? ''} — ${it['postcode'] ?? ''}'),
                                subtitle: Text('${it['kecamatan'] ?? ''} • ${it['kabupaten'] ?? ''} • ${it['provinsi'] ?? ''}'),
                                onTap: () {
                                  // Autofill semua field alamat saat pilih hasil
                                  widget.kodePosC.text = it['postcode'] ?? '';
                                  widget.desaC.text = it['desa'] ?? '';
                                  widget.dusunC.text = it['dusun'] ?? '';
                                  widget.kecamatanC.text = it['kecamatan'] ?? '';
                                  widget.kabupatenC.text = it['kabupaten'] ?? '';
                                  widget.provinsiC.text = it['provinsi'] ?? '';
                                  Navigator.of(ctx).pop();
                                },
                              );
                            },
                          ),
                  ),
                  // Tombol aksi Cari & Tutup
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: doSearch,
                            icon: const Icon(Icons.search),
                            label: const Text('Cari'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Tutup'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // -------------------------
  // Autofill kode pos from `wilayah` collection
  // -------------------------

  /// Coba autofill kode pos berdasarkan field yang sudah diisi
  Future<void> _tryAutoFillPostal() async {
    final desa = widget.desaC.text.trim();
    final kec = widget.kecamatanC.text.trim();
    final kab = widget.kabupatenC.text.trim();
    final prov = widget.provinsiC.text.trim();
    final dusun = widget.dusunC.text.trim();

    Query<Map<String, dynamic>> query = _db.collection('wilayah');
    bool usedConstraint = false;

    // Build query dengan constraint berdasarkan field yang sudah diisi
    try {
      if (desa.isNotEmpty) {
        query = query.where('desa', isEqualTo: desa);
        usedConstraint = true;
      }
      if (kec.isNotEmpty) {
        query = query.where('kecamatan', isEqualTo: kec);
        usedConstraint = true;
      }
      if (kab.isNotEmpty) {
        query = query.where('kabupaten', isEqualTo: kab);
        usedConstraint = true;
      }
      if (prov.isNotEmpty) {
        query = query.where('provinsi', isEqualTo: prov);
        usedConstraint = true;
      }
      if (dusun.isNotEmpty) {
        query = query.where('dusun_list', arrayContains: dusun);
        usedConstraint = true;
      }

      if (usedConstraint) {
        final snap = await query.limit(10).get();
        if (snap.docs.isNotEmpty) {
          final d = snap.docs.first.data();
          _applyWilayahDocToFields(d);
          return;
        }
      }
    } catch (e) {
      print('Query attempt failed (will fallback to client-side filter): $e');
    }

    // Fallback: filter client-side jika query gagal
    try {
      Query<Map<String, dynamic>> fetchQuery = _db.collection('wilayah');
      if (kec.isNotEmpty) {
        fetchQuery = fetchQuery.where('kecamatan', isEqualTo: kec);
      } else if (kab.isNotEmpty) {
        fetchQuery = fetchQuery.where('kabupaten', isEqualTo: kab);
      } else if (prov.isNotEmpty) {
        fetchQuery = fetchQuery.where('provinsi', isEqualTo: prov);
      }

      final snap = await fetchQuery.get();
      Map<String, dynamic>? best;

      for (final doc in snap.docs) {
        final d = doc.data();
        bool matched = false;

        // Matching desa / desa_list
        if (desa.isNotEmpty) {
          final docDesa = (d['desa'] ?? '').toString().trim();
          final docDesaList = d['desa_list'];
          if (docDesa.isNotEmpty && docDesa.toLowerCase() == desa.toLowerCase()) {
            matched = true;
          } else if (docDesaList is List) {
            for (final x in docDesaList) {
              if (x?.toString().toLowerCase() == desa.toLowerCase()) {
                matched = true;
                break;
              }
            }
          }
        }

        // Matching dusun
        if (!matched && dusun.isNotEmpty) {
          final docDusunList = d['dusun_list'] ?? d['dusun'];
          if (docDusunList is List) {
            for (final x in docDusunList) {
              if (x?.toString().toLowerCase() == dusun.toLowerCase()) {
                matched = true;
                break;
              }
            }
          } else if (docDusunList is String &&
              docDusunList.toString().toLowerCase().contains(dusun.toLowerCase())) {
            matched = true;
          }
        }

        // Matching kecamatan / kabupaten / provinsi
        if (!matched) {
          if (kec.isNotEmpty && (d['kecamatan'] ?? '').toString().toLowerCase() == kec.toLowerCase()) matched = true;
          else if (kab.isNotEmpty &&
              (d['kabupaten'] ?? d['regency'] ?? '').toString().toLowerCase() == kab.toLowerCase()) matched = true;
          else if (prov.isNotEmpty &&
              (d['provinsi'] ?? d['province'] ?? '').toString().toLowerCase() == prov.toLowerCase()) matched = true;
        }

        if (matched) {
          best = d;
          break;
        }
      }

      if (best != null) _applyWilayahDocToFields(best);
      else print('No matching wilayah doc found for current selection (client-side).');
    } catch (e, st) {
      print('Error querying wilayah for autofill (fallback): $e\n$st');
    }
  }

  /// Apply data doc wilayah ke field alamat
  void _applyWilayahDocToFields(Map<String, dynamic> d) {
    final code = (d['kodePos'] ?? d['code'] ?? d['kodepos'] ?? d['id'] ?? '').toString();
    final desa = (d['desa'] ?? '').toString();
    final kec = (d['kecamatan'] ?? '').toString();
    final kab = (d['kabupaten'] ?? d['regency'] ?? '').toString();
    final prov = (d['provinsi'] ?? d['province'] ?? '').toString();

    if (code.isNotEmpty) {
      widget.kodePosC.text = code;
      print('Autofill kodePos: $code (from doc)');
    }
    if (widget.desaC.text.trim().isEmpty && desa.isNotEmpty) widget.desaC.text = desa;
    if (widget.kecamatanC.text.trim().isEmpty && kec.isNotEmpty) widget.kecamatanC.text = kec;
    if (widget.kabupatenC.text.trim().isEmpty && kab.isNotEmpty) widget.kabupatenC.text = kab;
    if (widget.provinsiC.text.trim().isEmpty && prov.isNotEmpty) widget.provinsiC.text = prov;
  }

  // -------------------------
  // Autocomplete builder using local cache sets
  // -------------------------
  Widget _autocompleteField({
    required String label,
    required TextEditingController controller,
    required Set<String> sourceSet,
    required String fieldType,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Autocomplete<String>(
        optionsBuilder: (TextEditingValue textEditingValue) {
          final input = textEditingValue.text.toLowerCase().trim();
          if (input.isEmpty || sourceSet.isEmpty) return const Iterable<String>.empty();
          final filtered = sourceSet.where((s) => s.toLowerCase().contains(input)).take(50);
          return filtered;
        },
        displayStringForOption: (option) => option,
        onSelected: (selection) async {
          controller.text = selection;
          await _tryAutoFillPostal();
        },
        fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
          textController.text = controller.text;
          textController.selection = TextSelection.fromPosition(TextPosition(offset: textController.text.length));
          return TextFormField(
            controller: textController,
            focusNode: focusNode,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (v) => _requiredValidator(v, fieldName: label),
            decoration: _inputDecoration(label: label, prefixIcon: icon != null ? Icon(icon) : const Icon(Icons.search)),
            onChanged: (v) {
              controller.text = v;
            },
            onFieldSubmitted: (_) => onFieldSubmitted(),
          );
        },
        optionsViewBuilder: (context, onSelected, options) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4.0,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: 300, maxWidth: MediaQuery.of(context).size.width - 48),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final opt = options.elementAt(index);
                    return ListTile(
                      title: Text(opt),
                      onTap: () => onSelected(opt),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.grey[800]);
    final isNarrow = MediaQuery.of(context).size.width < 600;

    Widget formColumn() {
      return Card(
        elevation: 3,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Alamat Lengkap', style: titleStyle),
            const SizedBox(height: 8),
            _buildField(
              label: 'Jalan / Nama Jalan',
              controller: widget.jalanC,
              hint: 'Jl. Contoh No. 12 / Perumahan ...',
              prefixIcon: const Icon(Icons.streetview),
            ),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildField(
                    label: 'RT / RW',
                    controller: widget.rtRwC,
                    hint: '001/002',
                    prefixIcon: const Icon(Icons.format_list_numbered),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: _buildField(
                    label: 'Kode Pos',
                    controller: widget.kodePosC,
                    hint: 'Contoh: 40234',
                    prefixIcon: const Icon(Icons.mail_outline),
                    keyboardType: TextInputType.number,
                    suffixIcon: IconButton(icon: const Icon(Icons.search), onPressed: () => _showPostalSearchModal(context)),
                  ),
                ),
              ],
            ),
            if (_loadingWilayah) const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: LinearProgressIndicator()),
            if (_wilayahError != null) Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(_wilayahError!, style: const TextStyle(color: Colors.red))),
            _autocompleteField(label: 'Dusun', controller: widget.dusunC, sourceSet: _dusunSet, fieldType: 'dusun', icon: Icons.map),
            _autocompleteField(label: 'Desa / Kelurahan', controller: widget.desaC, sourceSet: _desaSet, fieldType: 'desa', icon: Icons.location_city),
            _autocompleteField(label: 'Kecamatan', controller: widget.kecamatanC, sourceSet: _kecamatanSet, fieldType: 'kecamatan', icon: Icons.place),
            _autocompleteField(label: 'Kabupaten / Kota', controller: widget.kabupatenC, sourceSet: _kabupatenSet, fieldType: 'kabupaten', icon: Icons.location_on),
            _autocompleteField(label: 'Provinsi', controller: widget.provinsiC, sourceSet: _provinsiSet, fieldType: 'provinsi', icon: Icons.flag),
            const SizedBox(height: 8),
            ElevatedButton.icon(onPressed: () => _showPostalSearchModal(context), icon: const Icon(Icons.search), label: const Text('Cari Kode Pos')),
            const SizedBox(height: 8),
            Text('Tip: Isi alamat selengkap mungkin agar surat/kontak dapat dikirim dengan benar.', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ]),
        ),
      );
    }

    if (isNarrow) {
      return SingleChildScrollView(child: formColumn());
    } else {
      // Layout 2 kolom untuk layar lebar
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(children: [
                    _buildField(label: 'Jalan / Nama Jalan', controller: widget.jalanC, hint: 'Jl. Contoh No. 12 / Perumahan ...', prefixIcon: const Icon(Icons.streetview)),
                    _autocompleteField(label: 'Dusun', controller: widget.dusunC, sourceSet: _dusunSet, fieldType: 'dusun', icon: Icons.map),
                    _autocompleteField(label: 'Kecamatan', controller: widget.kecamatanC, sourceSet: _kecamatanSet, fieldType: 'kecamatan', icon: Icons.place),
                  ]),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(children: [
                    _buildField(label: 'RT / RW', controller: widget.rtRwC, hint: '001/002', prefixIcon: const Icon(Icons.format_list_numbered)),
                    _autocompleteField(label: 'Desa / Kelurahan', controller: widget.desaC, sourceSet: _desaSet, fieldType: 'desa', icon: Icons.location_city),
                    _autocompleteField(label: 'Kabupaten / Kota', controller: widget.kabupatenC, sourceSet: _kabupatenSet, fieldType: 'kabupaten', icon: Icons.location_on),
                    Row(children: [
                      Expanded(child: _autocompleteField(label: 'Provinsi', controller: widget.provinsiC, sourceSet: _provinsiSet, fieldType: 'provinsi', icon: Icons.flag)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildField(
                          label: 'Kode Pos',
                          controller: widget.kodePosC,
                          hint: 'Contoh: 40234',
                          prefixIcon: const Icon(Icons.mail_outline),
                          keyboardType: TextInputType.number,
                          suffixIcon: IconButton(icon: const Icon(Icons.search), onPressed: () => _showPostalSearchModal(context)),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(onPressed: () => _showPostalSearchModal(context), icon: const Icon(Icons.search), label: const Text('Cari Kode Pos')),
                  ]),
                ),
              ),
            ),
          ]),
        ),
      );
    }
  }
}
