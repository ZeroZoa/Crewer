import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // Google 지도 위젯
import 'package:geolocator/geolocator.dart'; // 위치 정보 사용
import 'package:http/http.dart' as http;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 아이콘
import 'package:client/components/login_modal_screen.dart';
import '../config/api_config.dart';

// 지도 화면
class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng? _userLocation; // 사용자의 현재 위치
  final LatLng _defaultCenter = const LatLng(37.5665, 126.9780); // 초기 지도 중심 (서울시청)
  bool _loading = true; // 초기 로딩 플래그
  GoogleMapController? _mapController; // 지도 컨트롤러

  final List<LatLng> _pathPoints = []; // 경로를 구성할 위치 좌표들
  final Set<Polyline> _polylines = {}; // 지도 위에 그릴 선 정보

  Timer? _timer; // 시간 측정을 위한 타이머
  int _elapsedSeconds = 0; // 경과 시간 (초 단위)
  bool _isRunning = false; // 측정 중 여부
  double _totalDistance = 0.0; // 총 이동 거리 (미터)

  @override
  void initState() {
    super.initState();
    _initialize(); // 초기 위치 로딩
  }

  @override
  void dispose() {
    _timer?.cancel(); // 타이머 정리
    _positionSubscription?.cancel();
    super.dispose();
  }

  StreamSubscription<Position>? _positionSubscription;

  void _showLoginModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => LoginModalScreen(),
    );
  }

  // 위치 권한 요청 및 사용자 현재 위치 가져오기
  Future<void> _initialize() async {
    try {
      await _determinePosition(); // 현재 위치 가져오기
    } catch (e) {
      debugPrint('초기화 중 에러: $e');
    } finally {
      setState(() => _loading = false); // 로딩 종료
    }
  }

  // 위치 권한 요청 및 현재 위치 설정
  Future<void> _determinePosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      await Geolocator.openLocationSettings(); // 위치 설정 유도
      return;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );

    setState(() => _userLocation = LatLng(pos.latitude, pos.longitude));
    _mapController?.animateCamera(CameraUpdate.newLatLng(_userLocation!)); // 지도 이동
  }

  // Google Map 생성 시 호출
  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (_userLocation != null) {
      controller.animateCamera(CameraUpdate.newLatLng(_userLocation!)); // 지도 카메라 이동
    }
  }

  void _toggleRunning() {
    if (_isRunning) {
      // 측정 중이면 종료
      _timer?.cancel();                    // 타이머 정지
      _positionSubscription?.cancel();     // 위치 스트림 구독 취소
    } else {
      // 측정 시작
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _elapsedSeconds++); // 1초씩 증가
      });

      // 위치 변화 추적 시작
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).listen((position) {
        if (!mounted) return;
        final latlng = LatLng(position.latitude, position.longitude);
        setState(() {
          // 이전 위치와 거리 계산
          if (_pathPoints.isNotEmpty) {
            final last = _pathPoints.last;
            _totalDistance += Geolocator.distanceBetween(
              last.latitude, last.longitude,
              latlng.latitude, latlng.longitude,
            );
          }
          // 경로 업데이트
          _pathPoints.add(latlng);
          _polylines
            ..clear()
            ..add(
              Polyline(
                polylineId: const PolylineId('tracking'),
                color: const Color(0xFF9CB4CD),
                width: 4,
                points: List.from(_pathPoints),
              ),
            );
        });
      });
    }

    if (!mounted) return;
    setState(() => _isRunning = !_isRunning); // 상태 반전
  }

  // 종료 및 저장 후 초기화
  Future<void> _endAndSave() async {

    if (_totalDistance <= 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이동 거리가 없어 저장할 수 없습니다.')),
        );
      });
      return;
    }

    if (!_isRunning) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        _showLoginModal(); // 로그인 모달 띄우기
        setState(() => _isRunning = false);
        return;
      }

      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getRunningCreate()}');

      // 위도/경도 리스트를 path 형식으로 변환
      final List<Map<String, dynamic>> path = _pathPoints
          .map((p) => {'latitude': p.latitude, 'longitude': p.longitude})
          .toList();

      final body = json.encode({
        'totalDistance': _totalDistance,           // 미터 단위 거리
        'totalSeconds': _elapsedSeconds,           // 초 단위 시간
        'path': path                                // 위도/경도 경로 정보
      });

      try {
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: body,
        );

        if (response.statusCode == 201) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('기록 저장 완료되었습니다!')),
            );
          });
          setState(() {
            _elapsedSeconds = 0;
            _totalDistance = 0.0;
            _pathPoints.clear();
            _polylines.clear();
          });
        } else {
          debugPrint('저장 실패: ${response.statusCode}');
          debugPrint('응답 본문: ${response.body}');
        }
      } catch (e) {
        debugPrint('서버 통신 오류: $e');
      }
    }
  }

  // 시간 포맷 (00:00:00 형태)
  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    return [h, m, s].map((e) => e.toString().padLeft(2, '0')).join(':');
  }

  // 칼로리 계산 (1km당 60kcal 기준)
  double _calculateCalories(double meters) {
    const kcalPerKm = 60;
    return (meters / 1000) * kcalPerKm;
  }

  // 통계 정보 박스 UI 구성
  Widget _infoBox(String title, String value, String unit) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 3),
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        if (unit.isNotEmpty)
          Text(unit, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator()) // 로딩 중 표시
          : Column(
        children: [
          // 상단: 지도 (70%)
          Expanded(
            flex: 7,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _userLocation ?? _defaultCenter,
                zoom: 16,
              ),
              onMapCreated: _onMapCreated,
              myLocationEnabled: true,
              zoomControlsEnabled: true,
              polylines: _polylines,
              markers: {},
            ),
          ),
          // 하단: 통계 정보 및 버튼 (30%)
          Divider(
            thickness: 3,
            height: 3,  // ← 총 높이를 5로 설정하면 padding이 0이 됩니다
          ),
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 통계 정보
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _infoBox('달린 거리', (_totalDistance / 1000).toStringAsFixed(2), 'km'),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.grey,
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                      ),
                      _infoBox('칼로리', _calculateCalories(_totalDistance).toStringAsFixed(0), 'kcal'),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.grey,
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                      ),
                      _infoBox(
                        '평균 페이스',
                          (_elapsedSeconds > 10)
                            ? (_totalDistance / 1000 / _elapsedSeconds * 3600).toStringAsFixed(2)
                            : '-.--',
                        'km/h',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // 시간 + 버튼
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _infoBox('달린 시간', _formatDuration(_elapsedSeconds), ''),
                      ElevatedButton(
                        onPressed: _toggleRunning,   // 짧게 누르면 시작/정지
                        onLongPress: _endAndSave,    // 길게 누르면 종료+초기화
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF9CB4CD),
                          shape: const CircleBorder(),           // 동그란 모양
                          padding: const EdgeInsets.all(15),     // 안쪽 여백
                          minimumSize: const Size(55, 55),       // 최소 크기 지정
                        ),
                        child: Icon(
                          _isRunning ? LucideIcons.square : LucideIcons.play,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}