import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  String _role = '';
  String _name = '';
  String _nik = '';
  String _phone = '';
  String _profilePhotoPath = '';

  bool get isAuthenticated => _isAuthenticated;
  String get role => _role;
  String get name => _name;
  String get nik => _nik;
  String get phone => _phone;
  String get profilePhotoPath => _profilePhotoPath;

  AuthProvider() {
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null) {
      _isAuthenticated = true;
      _role = prefs.getString('role') ?? '';
      _nik = prefs.getString('nik') ?? '';
      
      // Load data kustom lokal jika ada, jika tidak pakai default
      _name = prefs.getString('custom_name_$_nik') ?? prefs.getString('name') ?? '';
      _phone = prefs.getString('custom_phone_$_nik') ?? prefs.getString('phone') ?? '';
      _profilePhotoPath = prefs.getString('custom_photo_$_nik') ?? prefs.getString('profilePhotoPath') ?? '';
      notifyListeners();
    }
  }

  Future<bool> login(String nik, String password) async {
    try {
      final response = await ApiService.login(nik, password);
      if (response['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        final user = response['user'];
        
        // Cek data kustom lokal untuk NIK ini, jika tidak ada baru gunakan respons dari API
        final responseName = prefs.getString('custom_name_$nik') ?? user?['name'] ?? '';
        final responsePhone = prefs.getString('custom_phone_$nik') ?? user?['phone'] ?? user?['no_telp'] ?? '';
        final responsePhoto = prefs.getString('custom_photo_$nik') ?? user?['foto'] ?? '';

        await prefs.setString('token', response['token']);
        await prefs.setString('role', response['role']);
        await prefs.setString('name', responseName);
        await prefs.setString('nik', nik);
        await prefs.setString('phone', responsePhone);
        await prefs.setString('profilePhotoPath', responsePhoto);

        _isAuthenticated = true;
        _role = response['role'];
        _name = responseName;
        _nik = nik;
        _phone = responsePhone;
        _profilePhotoPath = responsePhoto;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint("Login error: $e");
    }
    return false;
  }

  Future<void> logout() async {
    try {
      await ApiService.logout();
    } catch (e) {
      debugPrint("Logout error: $e");
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('role');
    await prefs.remove('name');
    await prefs.remove('nik');
    await prefs.remove('phone');
    await prefs.remove('profilePhotoPath');

    _isAuthenticated = false;
    _role = '';
    _name = '';
    _nik = '';
    _phone = '';
    _profilePhotoPath = '';
    notifyListeners();
  }

  Future<void> updateProfile({
    required String name,
    required String phone,
    String? password,
    String? photoPath,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    _name = name;
    _phone = phone;
    await prefs.setString('name', name);
    await prefs.setString('phone', phone);
    
    // Simpan data kustom lokal secara spesifik per NIK
    await prefs.setString('custom_name_$_nik', name);
    await prefs.setString('custom_phone_$_nik', phone);
    
    if (photoPath != null) {
      _profilePhotoPath = photoPath;
      await prefs.setString('profilePhotoPath', photoPath);
      await prefs.setString('custom_photo_$_nik', photoPath);
    }
    
    if (password != null && password.isNotEmpty) {
      // Simpan password kustom lokal secara spesifik per NIK
      await prefs.setString('custom_password_$_nik', password);
    }
    
    notifyListeners();
  }
}
