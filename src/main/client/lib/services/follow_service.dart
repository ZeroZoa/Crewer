import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class FollowService {
  static Future<Map<String, dynamic>> followUser(String username) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    if (token == null) throw Exception('로그인이 필요합니다');
    
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/follows/$username'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    
    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('팔로우 실패: ${response.body}');
    }
  }
  
  static Future<Map<String, dynamic>> unfollowUser(String username) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    if (token == null) throw Exception('로그인이 필요합니다');
    
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/follows/$username'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('언팔로우 실패: ${response.body}');
    }
  }
  
  static Future<Map<String, dynamic>> checkFollowStatus(String username) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    if (token == null) throw Exception('로그인이 필요합니다');
    
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/follows/check/$username'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('팔로우 상태 확인 실패: ${response.body}');
    }
  }
  
  static Future<List<Map<String, dynamic>>> getFollowers(String username) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    if (token == null) throw Exception('로그인이 필요합니다');
    
    String url;
    if (username == 'me') {
      // 내 프로필의 경우 현재 로그인한 사용자의 정보를 가져옴
      url = '${ApiConfig.baseUrl}/follows/followers/me';
    } else {
      url = '${ApiConfig.baseUrl}/follows/followers/$username';
    }
    
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['members']);
    } else {
      throw Exception('팔로워 목록 조회 실패: ${response.body}');
    }
  }
  
  static Future<List<Map<String, dynamic>>> getFollowing(String username) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    if (token == null) throw Exception('로그인이 필요합니다');
    
    String url;
    if (username == 'me') {
      // 내 프로필의 경우 현재 로그인한 사용자의 정보를 가져옴
      url = '${ApiConfig.baseUrl}/follows/following/me';
    } else {
      url = '${ApiConfig.baseUrl}/follows/following/$username';
    }
    
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['members']);
    } else {
      throw Exception('팔로잉 목록 조회 실패: ${response.body}');
    }
  }
} 