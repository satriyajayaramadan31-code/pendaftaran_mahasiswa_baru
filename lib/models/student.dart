import 'package:cloud_firestore/cloud_firestore.dart';

/// 🔹 Model data siswa
class Student {
  final String? id; // Optional, Firestore document ID
  final String nisn; // Nomor Induk Siswa Nasional
  final String nama;
  final String jenisKelamin;
  final String agama;
  final String tempatLahir;
  final DateTime? tanggalLahir;
  final String noHp;
  final String nik;
  final Address alamat; // Komposisi alamat
  final Parents orangTuaWali; // Komposisi data orang tua/wali
  final DateTime createdAt; // Timestamp pembuatan data

  Student({
    this.id,
    required this.nisn,
    required this.nama,
    required this.jenisKelamin,
    required this.agama,
    required this.tempatLahir,
    required this.tanggalLahir,
    required this.noHp,
    required this.nik,
    required this.alamat,
    required this.orangTuaWali,
    required this.createdAt,
  });

  /// 🔹 Konversi objek ke Map agar bisa disimpan di Firestore
  /// Gunakan Timestamp untuk field tanggal
  Map<String, dynamic> toMap() => {
        'nisn': nisn,
        'nama': nama,
        'jenisKelamin': jenisKelamin,
        'agama': agama,
        'tempatLahir': tempatLahir,
        'tanggalLahir': tanggalLahir != null ? Timestamp.fromDate(tanggalLahir!) : null,
        'noHp': noHp,
        'nik': nik,
        'alamat': alamat.toMap(),
        'orangTuaWali': orangTuaWali.toMap(),
        'createdAt': Timestamp.fromDate(createdAt),
      };

  /// 🔹 Buat objek Student dari Map Firestore
  /// Bisa menangani Timestamp atau String
  factory Student.fromMap(Map<String, dynamic> m, {String? id}) {
    // parsing tanggal lahir
    DateTime? parsedTanggalLahir;
    if (m['tanggalLahir'] != null) {
      final t = m['tanggalLahir'];
      if (t is Timestamp) {
        parsedTanggalLahir = t.toDate();
      } else if (t is String) {
        parsedTanggalLahir = DateTime.tryParse(t);
      }
    }

    // parsing createdAt
    DateTime parsedCreatedAt;
    if (m['createdAt'] != null) {
      final c = m['createdAt'];
      if (c is Timestamp) {
        parsedCreatedAt = c.toDate();
      } else if (c is String) {
        parsedCreatedAt = DateTime.tryParse(c) ?? DateTime.now();
      } else {
        parsedCreatedAt = DateTime.now();
      }
    } else {
      parsedCreatedAt = DateTime.now();
    }

    return Student(
      id: id,
      nisn: m['nisn'] ?? '',
      nama: m['nama'] ?? '',
      jenisKelamin: m['jenisKelamin'] ?? '',
      agama: m['agama'] ?? '',
      tempatLahir: m['tempatLahir'] ?? '',
      tanggalLahir: parsedTanggalLahir,
      noHp: m['noHp'] ?? '',
      nik: m['nik'] ?? '',
      alamat: Address.fromMap(Map<String, dynamic>.from(m['alamat'] ?? {})),
      orangTuaWali: Parents.fromMap(Map<String, dynamic>.from(m['orangTuaWali'] ?? {})),
      createdAt: parsedCreatedAt,
    );
  }

  @override
  String toString() => 'Student(nama: $nama, nisn: $nisn)';
}

/// 🔹 Model alamat siswa
class Address {
  final String jalan;
  final String rtRw;
  final String dusun;
  final String desa;
  final String kecamatan;
  final String kabupaten;
  final String provinsi;
  final String kodePos;

  Address({
    required this.jalan,
    required this.rtRw,
    required this.dusun,
    required this.desa,
    required this.kecamatan,
    required this.kabupaten,
    required this.provinsi,
    required this.kodePos,
  });

  /// 🔹 Konversi ke Map untuk Firestore
  Map<String, dynamic> toMap() => {
        'jalan': jalan,
        'rtRw': rtRw,
        'dusun': dusun,
        'desa': desa,
        'kecamatan': kecamatan,
        'kabupaten': kabupaten,
        'provinsi': provinsi,
        'kodePos': kodePos,
      };

  /// 🔹 Buat Address dari Map Firestore
  factory Address.fromMap(Map<String, dynamic> m) => Address(
        jalan: m['jalan'] ?? '',
        rtRw: m['rtRw'] ?? '',
        dusun: m['dusun'] ?? '',
        desa: m['desa'] ?? '',
        kecamatan: m['kecamatan'] ?? '',
        kabupaten: m['kabupaten'] ?? '',
        provinsi: m['provinsi'] ?? '',
        kodePos: m['kodePos'] ?? '',
      );

  @override
  String toString() => '$jalan, $desa, $kecamatan';
}

/// 🔹 Model data orang tua / wali siswa
class Parents {
  final String namaAyah;
  final String namaIbu;
  final String namaWali;
  final String alamatWali;

  Parents({
    required this.namaAyah,
    required this.namaIbu,
    required this.namaWali,
    required this.alamatWali,
  });

  /// 🔹 Konversi ke Map untuk Firestore
  Map<String, dynamic> toMap() => {
        'namaAyah': namaAyah,
        'namaIbu': namaIbu,
        'namaWali': namaWali,
        'alamatWali': alamatWali,
      };

  /// 🔹 Buat Parents dari Map Firestore
  factory Parents.fromMap(Map<String, dynamic> m) => Parents(
        namaAyah: m['namaAyah'] ?? '',
        namaIbu: m['namaIbu'] ?? '',
        namaWali: m['namaWali'] ?? '',
        alamatWali: m['alamatWali'] ?? '',
      );

  @override
  String toString() => 'Ayah: $namaAyah, Ibu: $namaIbu';
}
