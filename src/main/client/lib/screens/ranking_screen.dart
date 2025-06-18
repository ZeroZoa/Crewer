import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:client/components/login_modal_screen.dart';

/// 달리기 기록 목록 화면
class RankingScreen extends StatefulWidget {
  const RankingScreen({Key? key}) : super(key: key);

  @override
  _RankingScreenState createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  List<dynamic> _records = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkLoginAndFetch();
  }

  Future<void> _checkLoginAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      // 로그인 모달 표시
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => LoginModalScreen(),
      );
      final newToken = await prefs.getString('token');
      if (newToken == null) {
        context.pop();
        return;
      }
      await _fetchRecords(newToken);
    } else {
      await _fetchRecords(token);
    }
  }

  Future<void> _fetchRecords(String token) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final prefs = await SharedPreferences.getInstance();

    try {
      final resp = await http.get(
        Uri.parse('http://localhost:8080/running'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (resp.statusCode == 200) {
        _records = json.decode(resp.body) as List<dynamic>;
      }
      else if (resp.statusCode == 403 || resp.statusCode == 401) {
        // 토큰 만료 시 로그인 모달 띄우고, 모달이 반환한 새 토큰을 받는다.
        final newToken = await showModalBottomSheet<String>(
          context: context,
          isScrollControlled: true,
          builder: (_) => LoginModalScreen(),
        );

        // 사용자가 로그인 모달을 취소했으면 화면 닫기
        if (newToken == null) {
          context.pop();
          return;
        }

        // 받은 새 토큰을 SharedPreferences에 저장
        await prefs.setString('token', newToken);

        // 재귀 호출로 다시 fetch (새 토큰을 전달)
        return _fetchRecords(newToken);
      }
      else {
        _error = '레코드를 불러올 수 없습니다.';
      }
    }
    catch (e) {
      _error = '레코드를 불러올 수 없습니다.';
    }
    finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
            child: Text(
              _error!,
              style: const TextStyle(color: Colors.red),
            ),
          )
              : Padding(
            padding: const EdgeInsets.all(16),
            child: _buildRecordList(),
          ),
        ),
      ),
    );
  }

  Widget _buildRecordList() {
    // 날짜별 그룹핑
    final Map<String, List<dynamic>> grouped = {};
    for (var rec in _records) {
      final date = DateTime.parse(rec['createdAt'] as String);
      final key = DateFormat('yyyy년 M월 d일').format(date);
      grouped.putIfAbsent(key, () => []).add(rec);
    }
    final keys = grouped.keys.toList();

    return ListView.builder(
      itemCount: keys.length,
      itemBuilder: (context, idx) {
        final dateKey = keys[idx];
        final items = grouped[dateKey]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '$dateKey - 달리기 기록 -',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...items.map((rec) {
              final dt = DateTime.parse(rec['createdAt'] as String);
              final timeStr = DateFormat('HH:mm:ss').format(dt);
              final distKm = (rec['totalDistance'] as num) / 1000;
              final distStr = distKm.toStringAsFixed(2);
              final dur = Duration(seconds: rec['totalSeconds'] as int);
              final durStr = [
                dur.inHours,
                dur.inMinutes % 60,
                dur.inSeconds % 60
              ]
                  .map((e) => e.toString().padLeft(2, '0'))
                  .join(':');
              return ListTile(
                title: Text('$timeStr • ${distStr}km • $durStr'),
              );
            }),
          ],
        );
      },
    );
  }
}

// pubspec.yaml에 intl 패키지 추가 필요
