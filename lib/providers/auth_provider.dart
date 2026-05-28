import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  String _role = '';
  String _name = '';

  bool get isAuthenticated => _isAuthenticated;
  String get role => _role;
  String get name => _name;

  AuthProvider() {
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null) {
      _isAuthenticated = true;
      _role = prefs.getString('role') ?? '';
      _name = prefs.getString('name') ?? '';
      notifyListeners();
    }
  }

  Future<bool> login(String nik, String password) async {
    try {
      final response = await ApiService.login(nik, password);
      if (response['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', response['token']);
        await prefs.setString('role', response['role']);
        await prefs.setString('name', response['user']['name']);

        _isAuthenticated = true;
        _role = response['role'];
        _name = response['user']['name'];
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

    _isAuthenticated = false;
    _role = '';
    _name = '';
    notifyListeners();
  }
}
