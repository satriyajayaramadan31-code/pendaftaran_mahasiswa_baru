// lib/models/student.dart

class Student {
  final String nisn;
  final String nama;
  final String jenisKelamin;
  final String agama;
  final String tempatLahir;
  final DateTime? tanggalLahir;
  final String noHp;
  final String nik;
  final Address alamat;
  final Parents orangTuaWali;

  Student({
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
  });

  @override
  String toString() {
    return 'Student(nisn: $nisn, nama: $nama, jenisKelamin: $jenisKelamin, agama: $agama, tempatLahir: $tempatLahir, tanggalLahir: $tanggalLahir, noHp: $noHp, nik: $nik, alamat: $alamat, orangTuaWali: $orangTuaWali)';
  }
}

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

  @override
  String toString() {
    return 'Address(jalan: $jalan, rtRw: $rtRw, dusun: $dusun, desa: $desa, kecamatan: $kecamatan, kabupaten: $kabupaten, provinsi: $provinsi, kodePos: $kodePos)';
  }
}

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

  @override
  String toString() {
    return 'Parents(namaAyah: $namaAyah, namaIbu: $namaIbu, namaWali: $namaWali, alamatWali: $alamatWali)';
  }
}
