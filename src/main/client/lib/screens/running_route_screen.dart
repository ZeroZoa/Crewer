import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// RouteScreen: 전달된 경로와 기록 정보를 지도와 하단 패널에 표시합니다.
class RouteScreen extends StatelessWidget {
  final List<LatLng> path;
  final double distanceKm;
  final String timeStr;
  final String paceStr;
  final String runningDateStr;


  const RouteScreen({
    Key? key,
    required this.path,
    required this.distanceKm,
    required this.timeStr,
    required this.paceStr,
    required this.runningDateStr,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 초기 카메라 위치 설정: 경로가 있으면 첫 지점, 없으면 전 세계 뷰
    final initialCamera = path.isNotEmpty
        ? CameraPosition(target: path.first, zoom: 15)
        : const CameraPosition(target: LatLng(0, 0), zoom: 2);

    // 화면 전체 높이
    final screenSize  = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    final String calorie = (distanceKm * 60).toStringAsFixed(2);

    return Scaffold(
      body: Column(
        children: [
          //달리기 정보
          Container(
            height: screenHeight * 0.3,
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$runningDateStr의 달리기 기록',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,  // 추가: 텍스트 베이스라인 정렬
                    textBaseline: TextBaseline.alphabetic,            // 필수: 어떤 베이스라인을 쓸지 지정
                    children: [
                      Text(
                        '${distanceKm.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 76,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),  // 숫자와 단위 사이 여백
                      const Text(
                        'km',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.grey,
                        ),
                      ),
                    ]
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Row(
                    children: [
                      // 1) 페이스
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              paceStr,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Text(
                              '페이스',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),

                      // 세로 구분선
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.grey,
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                      ),

                      // 2) 시간
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              timeStr,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Text(
                              '시간',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),

                      // 세로 구분선
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.grey,
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                      ),

                      // 3) 칼로리
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              calorie,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Text(
                              '칼로리',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
          SizedBox(
            height: screenHeight * 0.45,
            width:  screenWidth * 0.9,
            child: GoogleMap(
              initialCameraPosition: initialCamera,
              polylines: {
                if (path.isNotEmpty)
                  Polyline(
                    polylineId: const PolylineId('running_route'),
                    points: path,
                    width: 5,
                    color: Colors.lime,
                  ),
              },
              markers: {
                if (path.isNotEmpty)
                  Marker(
                    markerId: const MarkerId('start'),
                    position: path.first,
                    infoWindow: const InfoWindow(title: '출발'),
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueBlue,   // 초록색 마커
                    ),
                  ),
                if (path.length > 1)
                  Marker(
                    markerId: const MarkerId('end'),
                    position: path.last,
                    infoWindow: const InfoWindow(title: '도착'),
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueRed,   // 초록색 마커
                    ),
                  ),
              },
            ),
          ),
        ],
      ),
    );
  }
}
