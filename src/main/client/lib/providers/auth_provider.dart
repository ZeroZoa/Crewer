import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decode/jwt_decode.dart';

import '../config/api_config.dart';


// ChangeNotifier: 이 클래스의 상태가 변경될 때마다, 이 상태를 구독(listen)하는 클래스
class AuthProvider with ChangeNotifier {

  String? _token;
  bool _isLoggedIn = false;

  String? get token => _token;
  bool get isLoggedIn => _isLoggedIn; // 외부에서는 이 getter를 통해 로그인 상태를 읽기만 할 수 있음.

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final String _tokenKey = 'token'; // 토큰을 저장할 키

  // 앱이 시작될 때, 저장된 토큰이 있는지 확인하여 로그인 상태를 초기화합니다.
  Future<void> checkLoginStatus() async {
    final storedToken = await _storage.read(key: _tokenKey);
    if (storedToken != null) {
      try {
        // 토큰 만료 여부 확인
        if (Jwt.isExpired(storedToken)) {
          // 만료되었다면 토큰 삭제
          await logout();
        } else {
          // 유효하다면 로그인 상태로 설정
          _token = storedToken;
          _isLoggedIn = true;
        }
      } catch (e) {
        // 토큰 파싱 오류 등 예외 발생 시 로그아웃 처리
        await logout();
      }
    } else {
      _isLoggedIn = false;
      _token = null;
    }
    notifyListeners(); // 상태가 변경되었음을 UI에 알립니다.
  }

  Future<void> fetchCurrentMember(String token) async {

  }


  // 성공하면 true, 실패하면 false를 반환하여 UI에 결과를 알려줍니다.
  Future<bool> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getLogin()}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final token = response.body;
        await _storage.write(key: _tokenKey, value: token);
        _token = token;
        _isLoggedIn = true;
        notifyListeners(); // 상태 변경을 UI에 알립니다.
        return true; // 성공했음을 알립니다.
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // 이메일(아이디) 존재 검증
  Future<bool> checkUsername(String username) async {
    try {
      final String url = '${ApiConfig.baseUrl}/members/check-username';
      final Map<String, String> headers = {'Content-Type': 'application/json'};
      final String body = jsonEncode({'username': username.trim()});

      final response = await http
          .post(Uri.parse(url), headers: headers, body: body)
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // 비밀번호 재설정
  Future<bool> resetPassword(String username, String newPassword) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/members/reset-password'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'username': username.trim(),
              'newPassword': newPassword,
            }),
          )
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// 로그아웃 시 호출될 메서드
  Future<void> logout() async {
    _token = null;
    await _storage.delete(key: _tokenKey);
    _isLoggedIn = false;
    notifyListeners();
  }
}