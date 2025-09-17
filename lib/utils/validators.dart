import 'package:flutter/material.dart';

/// Kelas Validators berisi kumpulan fungsi validasi untuk form
/// Digunakan untuk memeriksa input pengguna, misal kosong, angka, nomor HP, NIK, kode pos, dll.
class Validators {
  /// Validator wajib diisi (required)
  static String? requiredField(String? value, {String fieldName = 'Field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName tidak boleh kosong';
    }
    return null;
  }

  /// Validator numeric: harus angka
  static String? numeric(String? value, {String fieldName = 'Field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName tidak boleh kosong';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return '$fieldName harus berupa angka';
    }
    return null;
  }

  /// Validator nomor HP (10–15 digit angka)
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nomor HP tidak boleh kosong';
    }
    if (!RegExp(r'^[0-9]{10,15}$').hasMatch(value)) {
      return 'Nomor HP tidak valid';
    }
    return null;
  }

  /// Validator NIK (16 digit angka)
  static String? nik(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'NIK tidak boleh kosong';
    }
    if (value.length != 16 || !RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'NIK harus 16 digit angka';
    }
    return null;
  }

  /// Validator Kode Pos (5 digit angka)
  static String? kodePos(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Kode Pos tidak boleh kosong';
    }
    if (value.length != 5 || !RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'Kode Pos harus 5 digit angka';
    }
    return null;
  }

  /// Validator khusus untuk Dropdown
  static FormFieldValidator<String> dropdownRequired(String fieldName) {
    return (value) {
      if (value == null || value.isEmpty) {
        return '$fieldName harus dipilih';
      }
      return null;
    };
  }
}
