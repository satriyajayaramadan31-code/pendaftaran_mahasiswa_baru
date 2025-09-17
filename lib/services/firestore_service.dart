// lib/services/firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student.dart';

/// Service untuk berinteraksi dengan Firestore khusus koleksi "students"
/// Menyediakan CRUD: Create, Read (stream / by id), Update, Delete
class FirestoreService {
  /// Instance Firestore
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Nama koleksi di Firestore
  final String _col = 'students';

  /// 🔹 Stream daftar siswa
  /// Mengembalikan Stream<List<Student>> yang selalu update saat data berubah
  /// Data diurutkan berdasarkan field 'nama' ascending
  Stream<List<Student>> studentsStream() {
    return _db
        .collection(_col)
        .orderBy('nama') // urutkan berdasarkan nama siswa
        .snapshots() // ambil snapshot realtime
        .map((snap) => snap.docs
            .map((d) => Student.fromMap(
                d.data(), // data dari Firestore
                id: d.id)) // sertakan document id
            .toList());
  }

  /// 🔹 Tambah student baru
  /// [s] : object Student yang ingin disimpan
  /// Jika tanggalLahir atau createdAt null, otomatis menggunakan Timestamp.now()
  Future<void> addStudent(Student s) async {
    final data = s.toMap();

    // jika field tanggalLahir kosong, pakai Timestamp sekarang
    if (s.tanggalLahir == null) data['tanggalLahir'] = Timestamp.now();

    try {
      await _db.collection(_col).add(data); // simpan ke Firestore
      print('Student berhasil disimpan: ${s.nama}');
    } catch (e) {
      print('Gagal menyimpan student: $e');
      rethrow; // lempar error supaya bisa ditangani di caller
    }
  }

  /// 🔹 Ambil student berdasarkan document id
  /// Return Student jika ada, null jika tidak ditemukan
  Future<Student?> getStudentById(String id) async {
    try {
      final doc = await _db.collection(_col).doc(id).get(); // ambil document
      if (!doc.exists) return null; // jika tidak ada, kembalikan null
      return Student.fromMap(doc.data()!, id: doc.id);
    } catch (e) {
      print('Gagal mengambil student $id: $e');
      return null;
    }
  }

  /// 🔹 Update student berdasarkan document id
  /// [id] : document id student
  /// [s] : data Student baru
  Future<void> updateStudent(String id, Student s) async {
    final data = s.toMap();
    try {
      await _db.collection(_col).doc(id).update(data); // update data
      print('Student $id berhasil diperbarui');
    } catch (e) {
      print('Gagal update student $id: $e');
      rethrow;
    }
  }

  /// 🔹 Hapus student berdasarkan document id
  /// [id] : document id student
  Future<void> deleteStudent(String id) async {
    try {
      await _db.collection(_col).doc(id).delete(); // hapus document
      print('Student $id berhasil dihapus');
    } catch (e) {
      print('Gagal menghapus student $id: $e');
      rethrow;
    }
  }
}
