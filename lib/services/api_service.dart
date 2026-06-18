import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:typed_data';

class ApiService {
  // Mengambil Base URL dari file .env (jika tidak ada, fallback ke localhost)
  static String get baseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8000/api';

  static Future<Map<String, dynamic>> login(String nik, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'nik': nik, 'password': password}),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.post(
      Uri.parse('$baseUrl/logout'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getJadwal({String? tahunAjaranId}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    String url = '$baseUrl/jadwal';
    if (tahunAjaranId != null) {
      url += '?tahun_ajaran_id=$tahunAjaranId';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getRiwayatGlobal({String? tahunAjaranId}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    String url = '$baseUrl/riwayat';
    if (tahunAjaranId != null) {
      url += '?tahun_ajaran_id=$tahunAjaranId';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getRiwayatMapel(String mapelId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('$baseUrl/riwayat-mapel/$mapelId'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getAbsenMurid(String absenMasukId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('$baseUrl/absen-murid/$absenMasukId'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> saveAbsenMurid(
    String absenMasukId,
    List<dynamic> murids,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.post(
      Uri.parse('$baseUrl/absen-murid/$absenMasukId'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'murids': murids}),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> scanQr(String qrData) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.post(
      Uri.parse('$baseUrl/scan'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'qr_data': qrData}),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getIzinGuru() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('$baseUrl/izin'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> submitIzinGuru({
    required Map<String, String> data,
    String? filePath,
    Uint8List? fileBytes,
    String? fileName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/izin'));

    request.headers['Accept'] = 'application/json';
    request.headers['Authorization'] = 'Bearer $token';
    request.fields.addAll(data);

    // MOBILE
    if (filePath != null && filePath.isNotEmpty && !filePath.startsWith('http')) {
      if (await File(filePath).exists()) {
        request.files.add(
          await http.MultipartFile.fromPath('file', filePath),
        );
      }
    }

    // WEB
    if (fileBytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: fileName ?? 'file',
        ),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String phone,
    String? password,
    String? photoPath,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/profile/update'),
    );

    request.headers['Accept'] = 'application/json';
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['name'] = name;
    request.fields['no_telp'] = phone;

    if (password != null && password.isNotEmpty) {
      request.fields['password'] = password;
    }

    if (photoPath != null && photoPath.isNotEmpty && !photoPath.startsWith('http')) {
      if (await File(photoPath).exists()) {
        request.files.add(
          await http.MultipartFile.fromPath('foto', photoPath),
        );
      }
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    return jsonDecode(response.body);
  }
}
