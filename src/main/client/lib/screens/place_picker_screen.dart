import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../components/custom_app_bar.dart';
import '../config/api_config.dart';

class PlacePickerScreen extends StatefulWidget {
  const PlacePickerScreen({Key? key}) : super(key: key);

  @override
  _PlacePickerScreenState createState() => _PlacePickerScreenState();
}

class _PlacePickerScreenState extends State<PlacePickerScreen> {
  GoogleMapController? _mapController;
  LatLng? _currentPosition;
  LatLng? _selectedPosition;
  String _selectedAddress = '';
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  // 기본 지도 중심 (서울)
  static const LatLng _defaultCenter = LatLng(37.5665, 126.9780);
  String? _googleMapsApiKey;

  @override
  void initState() {
    super.initState();
    _getGoogleMapsApiKey();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _getGoogleMapsApiKey() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/config/google-maps-key'),
      );
      if (response.statusCode == 200) {
        setState(() {
          _googleMapsApiKey = response.body.replaceAll('"', '');
        });
      }
    } catch (e) {
      // API 키를 가져올 수 없으면 기본 geocoding 사용
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      // 위치 권한 확인
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // 현재 위치 가져오기
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getAddressFromLatLng(LatLng latLng) async {
    // Google Places API를 사용해서 더 상세한 주소 정보 가져오기
    if (_googleMapsApiKey != null) {
      await _getAddressFromGooglePlaces(latLng);
    } else {
      await _getAddressFromGeocoding(latLng);
    }
  }

  Future<void> _getAddressFromGooglePlaces(LatLng latLng) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://maps.googleapis.com/maps/api/geocode/json?latlng=${latLng.latitude},${latLng.longitude}&key=$_googleMapsApiKey&language=ko'
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          final result = data['results'][0];
          String address = result['formatted_address'];
          
          // "대한민국" 제거
          address = address.replaceAll('대한민국 ', '');
          
          setState(() {
            _selectedAddress = address;
          });
          return;
        }
      }
    } catch (e) {
      // Google Places API 실패 시 기본 geocoding 사용
    }
    
    // Google Places API 실패 시 기본 geocoding 사용
    await _getAddressFromGeocoding(latLng);
  }

  Future<void> _getAddressFromGeocoding(LatLng latLng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        
        // 더 상세한 주소 정보 구성 (대한민국 제외)
        List<String> addressParts = [];
        
        if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
          addressParts.add(place.administrativeArea!);
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          addressParts.add(place.locality!);
        }
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          addressParts.add(place.subLocality!);
        }
        if (place.thoroughfare != null && place.thoroughfare!.isNotEmpty) {
          addressParts.add(place.thoroughfare!);
        }
        if (place.subThoroughfare != null && place.subThoroughfare!.isNotEmpty) {
          addressParts.add(place.subThoroughfare!);
        }
        
        String address = addressParts.join(' ');
        
        // 주소가 너무 짧으면 좌표 정보 추가
        if (address.length < 10) {
          address = '$address (${latLng.latitude.toStringAsFixed(6)}, ${latLng.longitude.toStringAsFixed(6)})';
        }
        
        setState(() {
          _selectedAddress = address;
        });
      } else {
        setState(() {
          _selectedAddress = '주소를 찾을 수 없습니다 (${latLng.latitude.toStringAsFixed(6)}, ${latLng.longitude.toStringAsFixed(6)})';
        });
      }
    } catch (e) {
      setState(() {
        _selectedAddress = '주소를 찾을 수 없습니다 (${latLng.latitude.toStringAsFixed(6)}, ${latLng.longitude.toStringAsFixed(6)})';
      });
    }
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) return;

    try {
      List<Location> locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        LatLng newPosition = LatLng(locations.first.latitude, locations.first.longitude);
        
        setState(() {
          _selectedPosition = newPosition;
        });

        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(newPosition, 16.0),
        );

        await _getAddressFromLatLng(newPosition);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('검색 결과를 찾을 수 없습니다.')),
        );
      }
    }
  }

  void _onMapTap(LatLng position) {
    setState(() {
      _selectedPosition = position;
    });
    _getAddressFromLatLng(position);
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _selectPlace() {
    if (_selectedPosition != null) {
      context.pop({
        'latitude': _selectedPosition!.latitude,
        'longitude': _selectedPosition!.longitude,
        'address': _selectedAddress,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: CustomAppBar(
          appBarType: AppBarType.backOnly,
          title: const Text('장소 찾기'),
        ),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF002B)),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(
        appBarType: AppBarType.backOnly,
        title: const Text('장소 찾기'),
      ),
      body: Column(
        children: [
          // 검색 바
          Container(
            padding: const EdgeInsets.all(16),
            child: Theme(
              data: Theme.of(context).copyWith(
                textSelectionTheme: TextSelectionThemeData(
                  cursorColor: const Color(0xFFFF002B),
                  selectionColor: const Color(0xFFFF002B).withOpacity(0.3),
                  selectionHandleColor: const Color(0xFFFF002B),
                ),
              ),
              child: TextField(
                controller: _searchController,
                cursorColor: const Color(0xFFFF002B),
                decoration: InputDecoration(
                hintText: '장소를 검색하세요',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFFF002B), width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onSubmitted: _searchLocation,
            ),
            ),
          ),
          
          // 지도
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _currentPosition ?? _defaultCenter,
                zoom: 15.0,
              ),
                  onTap: _onMapTap,
                  markers: {
                    // 선택된 위치 마커 (빨간색)
                    if (_selectedPosition != null)
                      Marker(
                        markerId: const MarkerId('selected'),
                        position: _selectedPosition!,
                        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                        infoWindow: InfoWindow(title: _selectedAddress),
                      ),
                  },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                ),
              ],
            ),
          ),
          
          // 선택된 주소 표시 또는 안내 메시지
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.mapPin,
                  color: _selectedAddress.isNotEmpty ? const Color(0xFFFF002B) : Colors.grey,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedAddress.isNotEmpty 
                        ? _selectedAddress 
                        : '지도를 터치하거나 검색하여 장소를 선택하세요',
                    style: TextStyle(
                      fontSize: 16,
                      color: _selectedAddress.isNotEmpty ? Colors.black : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // 선택 완료 버튼
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 16 + MediaQuery.of(context).padding.bottom,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _selectedPosition != null ? _selectPlace : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedPosition != null 
                      ? const Color(0xFFFF002B) 
                      : Colors.grey.shade300,
                  foregroundColor: _selectedPosition != null 
                      ? Colors.white 
                      : Colors.grey.shade600,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  '완료',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
