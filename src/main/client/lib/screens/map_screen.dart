import 'dart:async';
import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// 지도 화면을 표시하는 StatefulWidget 클래스
class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng? _userLocation;                          // 사용자 현재 위치 저장
  final LatLng _defaultCenter = const LatLng(37.5665, 126.9780);
  bool _loading = true;                           // 로딩 상태 플래그
  GoogleMapController? _mapController;            // 지도 컨트롤러 참조

  final Health _health = Health();                // Health(걸음/거리) 사용
  int _stepCount = 0;                             // 걸음 수
  double _distance = 0.0;                         // 이동 거리 (미터)

  Timer? _timer;                                  // 경과 시간 측정용 타이머
  int _elapsedSeconds = 0;                        // 경과 시간(초)
  bool _isRunning = false;                        // 측정 중 여부

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// 위치 권한 요청 및 초기 데이터 로드
  Future<void> _initialize() async {
    try {
      await _determinePosition();
      await _fetchHealthData();
    } catch (e) {
      debugPrint('초기화 중 에러: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  /// 위치 서비스 활성화 및 현재 위치 조회
  Future<void> _determinePosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      await Geolocator.openLocationSettings();
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
    _mapController?.animateCamera(CameraUpdate.newLatLng(_userLocation!));
  }

  /// Health 데이터(걸음 수, 거리) 조회
  Future<void> _fetchHealthData() async {
    final types = [HealthDataType.STEPS, HealthDataType.DISTANCE_DELTA];
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    final granted = await _health.requestAuthorization(types);
    if (!granted) return;
    final data = await _health.getHealthDataFromTypes(
      startTime: midnight,
      endTime: now,
      types: types,
    );
    var steps = 0;
    var dist = 0.0;
    for (var pt in data) {
      if (pt.type == HealthDataType.STEPS) {
        steps += (pt.value as num).toInt();
      } else if (pt.type == HealthDataType.DISTANCE_DELTA) {
        dist += (pt.value as num).toDouble();
      }
    }
    setState(() {
      _stepCount = steps;
      _distance = dist;
    });
  }

  /// 구글 맵 생성 콜백
  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (_userLocation != null) {
      controller.animateCamera(CameraUpdate.newLatLng(_userLocation!));
    }
  }

  /// 시작/정지 토글
  void _toggleRunning() {
    if (_isRunning) {
      _timer?.cancel();
    } else {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() => _elapsedSeconds++);
      });
    }
    setState(() => _isRunning = !_isRunning);
  }

  /// 기록 종료 및 저장 후 초기화
  void _endAndSave() {
    if (!_isRunning) {
      // TODO: 백엔드 전송 로직 구현
      debugPrint('기록 저장: time=$_elapsedSeconds, steps=$_stepCount, dist=$_distance');
      setState(() {
        _elapsedSeconds = 0;
        _stepCount = 0;
        _distance = 0.0;
      });
    }
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    return [h, m, s].map((e) => e.toString().padLeft(2, '0')).join(':');
  }

  double _calculateCalories(double meters) {
    const kcalPerKm = 60;
    return (meters / 1000) * kcalPerKm;
  }

  /// 통계용 정보 박스 빌더
  Widget _infoBox(String title, String value, String unit) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: Color(0xFF9CB4CD))),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        if (unit.isNotEmpty)
          Text(unit, style: const TextStyle(color: Color(0xFF9CB4CD))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // 지도: 화면의 70%
          Expanded(
            flex: 7,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _userLocation ?? _defaultCenter,
                zoom: 18,
              ),
              onMapCreated: _onMapCreated,
              myLocationEnabled: true,
              zoomControlsEnabled: true,
              markers: {},
            ),
          ),
          // 통계 정보 + 버튼: 화면의 30%
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 상단 3개 통계
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _infoBox('달린 거리', (_distance / 1000).toStringAsFixed(2), 'km'),
                      _infoBox('칼로리', _calculateCalories(_distance).toStringAsFixed(0), 'kcal'),
                      _infoBox(
                        '평균 페이스',
                        _isRunning
                            ? (_distance / 1000 / _elapsedSeconds * 3600).toStringAsFixed(2)
                            : '0.00',
                        'km/h',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // 하단: 시간 + 시작/정지(onPressed) / 종료(onLongPress)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _infoBox('달린 시간', _formatDuration(_elapsedSeconds), ''),
                      ElevatedButton(
                        onPressed: _toggleRunning,  // 짧게 탭: 시작/정지
                        onLongPress: _endAndSave,    // 길게 누름: 종료+저장
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF9CB4CD),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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