import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/credential.dart';
import '../services/auth_service.dart';
import '../services/encryption_service.dart';

/// Handles all communication with the SafeWord Node.js backend.
/// Credentials are encrypted before sending and decrypted on receipt.
class ApiService {
  static final String _base = AppConfig.apiBaseUrl;

  static Map<String, String> get _headers {
    final token = AuthService.accessToken;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static void _checkUnlocked() {
    if (!AuthService.isUnlocked) {
      throw Exception('Vault is locked. Please unlock to continue.');
    }
  }

  // ─── Fetch All ────────────────────────────────────────────────────────────

  static Future<List<Credential>> getCredentials({String? search}) async {
    _checkUnlocked();

    final uri = Uri.parse('$_base/api/credentials').replace(
      queryParameters: search != null && search.isNotEmpty
          ? {'search': search}
          : null,
    );

    final response = await http.get(uri, headers: _headers).timeout(
      const Duration(seconds: 10),
    );

    if (response.statusCode == 401) {
      throw Exception('Session expired. Please log in again.');
    }

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'Failed to fetch credentials');
    }

    final List<dynamic> list = jsonDecode(response.body);
    final derivedKey = AuthService.derivedKey!;

    return list.map((json) {
      final cred = Credential.fromJson(json as Map<String, dynamic>);
      // Decrypt password client-side
      try {
        cred.decryptedPassword = EncryptionService.decrypt(
          cred.password,
          derivedKey,
          cred.iv,
        );
      } catch (_) {
        cred.decryptedPassword = ''; // decryption failed (wrong key?)
      }
      return cred;
    }).toList();
  }

  // ─── Fetch One ────────────────────────────────────────────────────────────

  static Future<Credential> getCredential(String id) async {
    _checkUnlocked();

    final response = await http
        .get(Uri.parse('$_base/api/credentials/$id'), headers: _headers)
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'Credential not found');
    }

    final cred = Credential.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
    cred.decryptedPassword = EncryptionService.decrypt(
      cred.password,
      AuthService.derivedKey!,
      cred.iv,
    );
    return cred;
  }

  // ─── Create ───────────────────────────────────────────────────────────────

  static Future<Credential> createCredential({
    required String title,
    String? username,
    required String plainPassword,
    String? moreInfo,
    String? category,
  }) async {
    _checkUnlocked();

    final user = AuthService.currentUser!;
    final salt = user.userMetadata?['salt'] as String;
    final derivedKey = AuthService.derivedKey!;

    final encResult = EncryptionService.encrypt(plainPassword, derivedKey);

    final body = jsonEncode({
      'title': title,
      'username': username,
      'password': encResult['encrypted'],
      'more_info': moreInfo,
      'category': category,
      'iv': encResult['iv'],
      'salt': salt,
    });

    final response = await http
        .post(Uri.parse('$_base/api/credentials'),
            headers: _headers, body: body)
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 201) {
      final resp = jsonDecode(response.body);
      throw Exception(resp['error'] ?? 'Failed to create credential');
    }

    final cred = Credential.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
    cred.decryptedPassword = plainPassword;
    return cred;
  }

  // ─── Update ───────────────────────────────────────────────────────────────

  static Future<Credential> updateCredential({
    required String id,
    required String title,
    String? username,
    required String plainPassword,
    String? moreInfo,
    String? category,
  }) async {
    _checkUnlocked();

    final derivedKey = AuthService.derivedKey!;
    final encResult = EncryptionService.encrypt(plainPassword, derivedKey);

    final body = jsonEncode({
      'title': title,
      'username': username,
      'password': encResult['encrypted'],
      'more_info': moreInfo,
      'category': category,
      'iv': encResult['iv'],
    });

    final response = await http
        .put(Uri.parse('$_base/api/credentials/$id'),
            headers: _headers, body: body)
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      final resp = jsonDecode(response.body);
      throw Exception(resp['error'] ?? 'Failed to update credential');
    }

    final cred = Credential.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
    cred.decryptedPassword = plainPassword;
    return cred;
  }

  // ─── Delete ───────────────────────────────────────────────────────────────

  static Future<void> deleteCredential(String id) async {
    _checkUnlocked();

    final response = await http
        .delete(Uri.parse('$_base/api/credentials/$id'), headers: _headers)
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 204) {
      final resp = jsonDecode(response.body);
      throw Exception(resp['error'] ?? 'Failed to delete credential');
    }
  }
}
