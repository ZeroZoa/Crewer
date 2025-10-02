import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../components/custom_app_bar.dart';

class RouteScreen extends StatefulWidget {
  final List<LatLng> path;
  final double distanceKm;
  final String timeStr;
  final String paceStr;
  final String runningDateStr;

  const RouteScreen({
    super.key,
    required this.path,
    required this.distanceKm,
    required this.timeStr,
    required this.paceStr,
    required this.runningDateStr,
  });

  @override
  State<RouteScreen> createState() => _RouteScreenState();
}

class _RouteScreenState extends State<RouteScreen> {
  BitmapDescriptor? startMarkerIcon;
  BitmapDescriptor? endMarkerIcon;
  String? _mapStyle;

  // 개선 1: 로딩 상태를 관리할 변수 추가
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // 개선 2: 모든 데이터 로딩을 initState에서 한 번에 처리
    _loadMapAssets();
  }

  // 개선 3: 지도 관련 모든 asset을 한 번에 로드하는 함수
  Future<void> _loadMapAssets() async {
    // Future.wait를 사용해 모든 비동기 작업이 끝날 때까지 기다립니다.
    await Future.wait([
      _loadMapStyle(),
      _loadCustomMarkers(),
    ]);

    // 모든 로딩이 끝난 후, 로딩 상태를 false로 변경하여 화면을 갱신합니다.
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadMapStyle() async {
    try {
      _mapStyle = await rootBundle.loadString('assets/map_style.json');
    } catch (e) {
      print('지도 스타일 로딩 실패: $e');
      // 스타일 로딩에 실패해도 앱이 멈추지 않도록 기본 스타일을 유지합니다.
    }
  }

  // 개선 4: 최신 방식으로 마커 아이콘 로딩
  Future<void> _loadCustomMarkers() async {
    // fromAssetImage는 ImageConfiguration이 필요 없어 더 간결합니다.
    startMarkerIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(128, 128)),
      'assets/images/start_pin.png',
    );
    endMarkerIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(128, 128)),
      'assets/images/end_pin.png',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: CustomAppBar(
        appBarType: AppBarType.close,
        title: const Padding(
          padding: EdgeInsets.only(left: 0, top: 4),
          child: Text('경로보기', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 22)),
        ),
      ),
      body: Column(
        children: [
          _buildInfoPanel(context),
          Expanded(
            // 수정: 통합된 로딩 변수를 사용
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildMapView(),
          ),
        ],
      ),
    );
  }

  Widget _buildMapView() {
    final initialCamera = widget.path.isNotEmpty
        ? CameraPosition(target: widget.path.first, zoom: 15)
        : const CameraPosition(target: LatLng(0, 0), zoom: 2);

    return GoogleMap(
      style: _mapStyle, // null이어도 기본 스타일로 동작합니다.
      initialCameraPosition: initialCamera,
      polylines: {
        if (widget.path.isNotEmpty)
          Polyline(
            polylineId: const PolylineId('running_route'),
            points: widget.path,
            width: 5,
            color: const Color(0xFFFF002B),
          ),
      },
      markers: {
        if (widget.path.isNotEmpty && startMarkerIcon != null)
          Marker(
            markerId: const MarkerId('Start'),
            position: widget.path.first,
            infoWindow: const InfoWindow(title: 'Start'),
            icon: startMarkerIcon!,
          ),
        if (widget.path.length > 1 && endMarkerIcon != null)
          Marker(
            markerId: const MarkerId('End'),
            position: widget.path.last,
            infoWindow: const InfoWindow(title: 'End'),
            icon: endMarkerIcon!,
          ),
      },
    );
  }

  // _buildInfoPanel과 _infoBox는 수정할 필요가 없으므로 그대로 둡니다.
  Widget _buildInfoPanel(BuildContext context) {
    final String calorie = (widget.distanceKm * 60).toStringAsFixed(2);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: const Color(0xFFFAFAFA),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${widget.runningDateStr}의 달리기 기록', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                widget.distanceKm.toStringAsFixed(2),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 70, fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 4),
              const Text('km', style: TextStyle(fontSize: 20, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _infoBox('평균 페이스', widget.paceStr)),
              Expanded(child: _infoBox('달린 시간', widget.timeStr)),
              Expanded(child: _infoBox('칼로리', calorie)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoBox(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
          ],
        ),
        Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}
