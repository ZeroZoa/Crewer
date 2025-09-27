import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import '../config/api_config.dart';
import '../components/custom_app_bar.dart';

enum EvaluationType {
  EXCELLENT(2.0, '최고예요!', '😍'),
  GOOD(1.0, '좋았어요', '😊'),
  NEUTRAL(0.0, '괜찮았어요', '😐'),
  BAD(-1.0, '아쉬웠어요', '😔'),
  TERRIBLE(-2.0, '최악이었어요', '😡');

  const EvaluationType(this.temperatureChange, this.displayText, this.emoji);
  
  final double temperatureChange;
  final String displayText;
  final String emoji;
}

class EvaluationScreen extends StatefulWidget {
  final String groupFeedId;
  
  const EvaluationScreen({Key? key, required this.groupFeedId}) : super(key: key);

  @override
  _EvaluationScreenState createState() => _EvaluationScreenState();
}

class _EvaluationScreenState extends State<EvaluationScreen> {
  List<Map<String, dynamic>> _crewMembers = [];
  Map<String, EvaluationType> _evaluations = {};
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _loadCrewMembers();
  }

  Future<void> _loadCrewMembers() async {
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) {
        setState(() {
          _error = '로그인이 필요합니다';
          _isLoading = false;
        });
        return;
      }

      // 그룹 피드 참여자 목록을 가져오는 API 호출
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getGroupFeedParticipants(widget.groupFeedId)}'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        
        // 현재 사용자 정보 가져오기
        final currentUserResponse = await http.get(
          Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getProfileMe()}'),
          headers: {'Authorization': 'Bearer $token'},
        );
        
        String? currentUsername;
        if (currentUserResponse.statusCode == 200) {
          final currentUserData = json.decode(currentUserResponse.body);
          currentUsername = currentUserData['username']?.toString();
        }
        
        // 자기 자신을 제외한 크루원 목록 생성
        final List<Map<String, dynamic>> filteredMembers = [];
        for (var member in data) {
          if (currentUsername != null && member['username'].toString() != currentUsername) {
            filteredMembers.add(Map<String, dynamic>.from(member));
          } else if (currentUsername == null) {
            // 현재 사용자 정보를 가져올 수 없는 경우 모든 멤버 포함
            filteredMembers.add(Map<String, dynamic>.from(member));
          }
        }
        
        setState(() {
          _crewMembers = filteredMembers;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = '크루원 정보를 불러올 수 없습니다';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = '네트워크 오류가 발생했습니다';
        _isLoading = false;
      });
    }
  }

  Future<void> _submitEvaluations() async {
    if (_evaluations.length != _crewMembers.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 크루원을 평가해주세요')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final token = await _storage.read(key: 'token');
      if (token == null) return;

      // 백엔드에서 기대하는 Map 형태로 변환
      final Map<String, String> evaluations = {};
      _evaluations.forEach((memberId, evaluationType) {
        evaluations[memberId] = evaluationType.name;
      });

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.submitEvaluation()}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'groupFeedId': int.parse(widget.groupFeedId), // String을 int로 변환
          'evaluations': evaluations,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('평가가 완료되었습니다')),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('평가 제출에 실패했습니다')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('네트워크 오류가 발생했습니다')),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: CustomAppBar(
        appBarType: AppBarType.backOnly,
        title: const Text(
          '크루원 평가',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadCrewMembers,
                        child: const Text('다시 시도'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _crewMembers.length,
                        itemBuilder: (context, index) {
                          final member = _crewMembers[index];
                          return _buildMemberEvaluationCard(member);
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: const Offset(0, -3),
                          ),
                        ],
                      ),
                      child: SafeArea(
                        child: SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitEvaluations,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF002B),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isSubmitting
                                ? const CircularProgressIndicator(color: Colors.white)
                                : Text(
                                    '평가 완료 (${_evaluations.length}/${_crewMembers.length})',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildMemberEvaluationCard(Map<String, dynamic> member) {
    final memberId = member['id'].toString();
    final currentEvaluation = _evaluations[memberId];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 크루원 정보
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundImage: member['avatarUrl'] != null
                      ? NetworkImage(member['avatarUrl'])
                      : null,
                  child: member['avatarUrl'] == null
                      ? const Icon(Icons.person, size: 30)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member['nickname'] ?? '알 수 없음',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '현재 온도: ${member['temperature']?.toStringAsFixed(1) ?? '36.5'}°C',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 평가 옵션들
            Text(
              '이 크루원을 어떻게 평가하시나요?',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            
            // 평가 버튼들
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: EvaluationType.values.map((type) {
                final isSelected = currentEvaluation == type;
                return _buildEvaluationButton(type, memberId, isSelected);
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEvaluationButton(EvaluationType type, String memberId, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _evaluations[memberId] = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF002B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF002B) : Colors.grey[300]!,
            width: 1.5,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: const Color(0xFFFF002B).withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              type.emoji,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 8),
            Text(
              type.displayText,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
