import 'package:flutter/material.dart';

class Validators {
  static String? requiredField(String? value, {String fieldName = 'Field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName tidak boleh kosong';
    }
    return null;
  }

  static String? numeric(String? value, {String fieldName = 'Field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName tidak boleh kosong';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return '$fieldName harus berupa angka';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nomor HP tidak boleh kosong';
    }
    if (!RegExp(r'^[0-9]{10,15}$').hasMatch(value)) {
      return 'Nomor HP tidak valid';
    }
    return null;
  }

  static String? nik(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'NIK tidak boleh kosong';
    }
    if (value.length != 16 || !RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'NIK harus 16 digit angka';
    }
    return null;
  }

  static String? kodePos(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Kode Pos tidak boleh kosong';
    }
    if (value.length != 5 || !RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'Kode Pos harus 5 digit angka';
    }
    return null;
  }

  /// ✅ Validator tambahan khusus untuk Dropdown
  static FormFieldValidator<String> dropdownRequired(String fieldName) {
    return (value) {
      if (value == null || value.isEmpty) {
        return '$fieldName harus dipilih';
      }
      return null;
    };
  }
}
