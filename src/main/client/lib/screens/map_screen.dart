import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // Google 지도 위젯
import 'package:geolocator/geolocator.dart'; // 위치 정보 사용
import 'package:http/http.dart' as http;
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
  bool _loading = true;
  bool _isExpanded = true;
  GoogleMapController? _mapController; // 지도 컨트롤러

  final String _tokenKey = 'token';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final LatLng _defaultCenter = const LatLng(37.5665, 126.9780); // 초기 지도 중심 (서울시청)
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

  Future<String?> _showLoginModal() async {
    final newToken = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => LoginModalScreen(),
    );
    return newToken;
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

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );

    setState(() => _userLocation = LatLng(position.latitude, position.longitude));
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

    // _isRunning 체크는 필요 없어 보입니다. 이 함수는 '종료 및 저장'이므로
    // 항상 !_isRunning 상태일 때 호출될 것으로 예상됩니다.
    // if (!_isRunning) { ... } -> 이 if문은 제거해도 좋습니다.

    final token = await _storage.read(key: _tokenKey);

    if (token == null) {
      _showLoginModal();
      return;
    }

    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getRunningCreate()}');
    final List<Map<String, dynamic>> path = _pathPoints
        .map((p) => {'latitude': p.latitude, 'longitude': p.longitude})
        .toList();

    final body = json.encode({
      'totalDistance': _totalDistance,
      'totalSeconds': _elapsedSeconds,
      'path': path
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
        // 1. 저장 성공
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('기록이 성공적으로 저장되었습니다!')),
          );
        });
        // 상태 초기화
        setState(() {
          _elapsedSeconds = 0;
          _totalDistance = 0.0;
          _pathPoints.clear();
          _polylines.clear();
        });
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        // 2. 토큰 만료 또는 인증 실패
        // 로그인 모달을 띄워 새 토큰을 받아옵니다.
        final newToken = await _showLoginModal(); // _showLoginModal이 새 토큰을 반환하도록 수정

        if (newToken != null) {
          // 새 토큰을 받았다면, 저장 로직을 다시 시도합니다. (재귀 호출)
          await _endAndSave();
        }
        // 새 토큰을 받지 못했다면(로그인 취소) 아무것도 하지 않고 함수 종료

      } else {
        // 3. 그 외 서버 에러
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('서버 문제로 저장에 실패했습니다: ${response.statusCode}')),
          );
        });
        debugPrint('저장 실패: ${response.statusCode}');
        debugPrint('응답 본문: ${response.body}');
      }

    } catch (e) {
      // 4. 네트워크 통신 등 클라이언트 측 에러
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('네트워크 오류로 저장에 실패했습니다.')),
        );
      });
      debugPrint('서버 통신 오류: $e');
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
        Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
            Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(width: 3,),
            if (unit.isNotEmpty)
              Text(unit, style: const TextStyle(fontSize: 10)),
          ]
        ),

        Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // body는 로딩 상태에 따라 다른 위젯을 보여줍니다.
      body: _loading
          ? const Center(child: CircularProgressIndicator()) // 로딩 중
          : Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _userLocation ?? _defaultCenter,
              zoom: 16,
            ),
            onMapCreated: _onMapCreated,
            myLocationEnabled: true,
            zoomControlsEnabled: true,
            polylines: _polylines,
            markers: {},
            padding: EdgeInsets.only(bottom: _isExpanded ? 230 : 110),
          ),

          // 2. 전경: 컨트롤 패널이 지도 위에 올라갑니다.
          //    Positioned 위젯으로 화면 하단에 정확히 배치합니다.
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: GestureDetector(
              onVerticalDragEnd: (details) {
                if (details.primaryVelocity! < -200) {
                  if (!_isExpanded) setState(() => _isExpanded = true);
                } else if (details.primaryVelocity! > 200) {
                  if (_isExpanded) setState(() => _isExpanded = false);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                height: _isExpanded ? 250 : 150,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color.fromARGB(60, 0, 0, 0),
                      blurRadius: 10,
                      offset: Offset(0, -5),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Expanded(
                      child: _isExpanded
                          ? _buildExpandedView()
                          : _buildCollapsedView(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
            children: [
            _infoBox('달린 시간', _formatDuration(_elapsedSeconds), ''),
          ],
        ),
        const SizedBox(height: 15),
        // 통계 정보
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _infoBox('달린 거리', (_totalDistance / 1000).toStringAsFixed(2), 'km'),
            _infoBox('칼로리', _calculateCalories(_totalDistance).toStringAsFixed(0), 'kcal'),
            _infoBox('평균 페이스', _formatPace(_totalDistance, _elapsedSeconds), 'km/h'),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.06,
          child: ElevatedButton(
            onPressed: _toggleRunning,
            onLongPress: _endAndSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isRunning ? Colors.grey.shade300 : const Color(0xFFFF002B),
              foregroundColor: _isRunning ? Colors.grey.shade800 : Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16), // 숫자가 작을수록 각진 모양이 됩니다.
              ),
            ),
            child: Text(
              _isRunning ? "운동 끝내기" : "운동 시작하기",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        ),
      ],
    );
  }

  Widget _buildCollapsedView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _infoBox('달린 시간', _formatDuration(_elapsedSeconds), ''),
            const SizedBox(width: 64),
            _infoBox('달린 거리', (_totalDistance / 1000).toStringAsFixed(2), 'km'),
          ],
        ),
        SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.06,
            child: ElevatedButton(
              onPressed: _toggleRunning,
              onLongPress: _endAndSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isRunning ? Colors.grey.shade300 : const Color(0xFFFF002B),
                foregroundColor: _isRunning ? Colors.grey.shade800 : Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16), // 숫자가 작을수록 각진 모양이 됩니다.
                ),
              ),
              child: Text(
                _isRunning ? "운동 끝내기" : "운동 시작하기",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
        ),
      ]
    );
  }
}

String _formatPace(double totalDistance, int totalSeconds) {
  if (totalDistance < 1) return "-'--\"";
  double paceInSecondsPerKm = totalSeconds / (totalDistance / 1000);
  int minutes = paceInSecondsPerKm ~/ 60;
  int seconds = (paceInSecondsPerKm % 60).round();
  return "$minutes'${seconds.toString().padLeft(2, '0')}\"";
}

