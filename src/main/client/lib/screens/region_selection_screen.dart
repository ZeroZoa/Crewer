import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import '../config/api_config.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RegionSelectionScreen extends StatefulWidget {
  final String provinceId;
  final String provinceName;
  final Function(String) onDistrictSelected;

  const RegionSelectionScreen({
    Key? key,
    required this.provinceId,
    required this.provinceName,
    required this.onDistrictSelected,
  }) : super(key: key);

  @override
  _RegionSelectionScreenState createState() => _RegionSelectionScreenState();
}

class _RegionSelectionScreenState extends State<RegionSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedDistrictId;
  String? _selectedDistrictName;
  
  List<Map<String, dynamic>> _allDistricts = []; // 모든 행정동
  List<Map<String, dynamic>> _filteredDistricts = []; // 검색 결과
  List<Map<String, dynamic>> _searchResults = []; // 자동완성 결과
  
  bool _isLoadingDistricts = false;
  bool _isSearching = false;
  
  // Google Maps 관련 변수들
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polygon> _polygons = {}; // 폴리곤 추가
  LatLng _center = LatLng(37.5665, 126.9780); // 서울 중심점
  double _zoom = 10.0;

  bool _isSelectingFromAutocomplete = false; // 자동완성에서 선택 중인지 플래그

  @override
  void initState() {
    super.initState();
    _loadAllDistricts();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllDistricts() async {
    setState(() {
      _isLoadingDistricts = true;
    });

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/regions/${widget.provinceId}/districts'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final districts = List<Map<String, dynamic>>.from(data['data']);
          setState(() {
            _allDistricts = districts;
            _filteredDistricts = List.from(_allDistricts);
          });
          
          if (districts.isNotEmpty) {
            _adjustMapCenter(districts);
          }
        }
      }
    } catch (e) {
      print('행정동 목록 로드 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('행정동 목록을 불러오는데 실패했습니다')),
      );
    } finally {
      setState(() {
        _isLoadingDistricts = false;
      });
    }
  }

  void _addMarkersToMap(List<Map<String, dynamic>> districts) {
    Set<Marker> markers = {};
    
    for (final district in districts) {
      final coordinates = district['coordinates'];
      if (coordinates != null) {
        final lat = coordinates['lat']?.toDouble() ?? 0.0;
        final lng = coordinates['lng']?.toDouble() ?? 0.0;
        
        if (lat != 0.0 && lng != 0.0) {
          final isSelected = _selectedDistrictId == district['regionId'];
          
          markers.add(Marker(
            markerId: MarkerId(district['regionId']),
            position: LatLng(lat, lng),
            infoWindow: InfoWindow(
              title: district['regionName'],
              snippet: district['fullName'],
            ),
            icon: isSelected 
                ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed)
                : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            onTap: () => _selectDistrict(district),
          ));
        }
      }
    }
    
    setState(() {
      _markers = markers;
    });
  }

  void _addSelectedDistrictMarker(Map<String, dynamic> district) {

    setState(() {
      _markers = {};
    });
    
    _loadDistrictPolygon(district['regionId']);
  }

  Future<void> _loadDistrictPolygon(String districtId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/regions/districts/$districtId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final district = data['data'];
          final geojsonDataString = district['geojsonData'];
          
          if (geojsonDataString != null && geojsonDataString.isNotEmpty) {
            try {
              final geojsonData = json.decode(geojsonDataString);
              
              final polygon = _parseGeoJSONToPolygon(geojsonData, district['regionName']);
              if (polygon != null) {
                setState(() {
                  _markers = {};
                  _polygons = {polygon};
                });
                
                _moveMapToPolygon(polygon.points);
              } else {
                _createTestPolygon(district);
              }
            } catch (parseError) {
              _createTestPolygon(district);
            }
          } else {
            _createTestPolygon(district);
          }
        }
      }
    } catch (e) {
      print('폴리곤 로드 오류: $e');
    }
  }

  void _createTestPolygon(Map<String, dynamic> district) {
    final coordinates = district['coordinates'];
    if (coordinates != null) {
      final lat = coordinates['lat']?.toDouble() ?? 0.0;
      final lng = coordinates['lng']?.toDouble() ?? 0.0;
      
      if (lat != 0.0 && lng != 0.0) {
        final List<LatLng> points = [
          LatLng(lat - 0.001, lng - 0.001),
          LatLng(lat - 0.001, lng + 0.001),
          LatLng(lat + 0.001, lng + 0.001),
          LatLng(lat + 0.001, lng - 0.001),
        ];
        
        final testPolygon = Polygon(
          polygonId: PolygonId('${district['regionName']}_test'),
          points: points,
          strokeWidth: 3,
          strokeColor: Colors.blue,
          fillColor: Colors.blue.withOpacity(0.3),
        );
        
        setState(() {
          _markers = {};
          _polygons = {testPolygon};
        });
        
        _moveMapToPolygon(points);
      }
    }
  }

  Polygon? _parseGeoJSONToPolygon(Map<String, dynamic> geojsonData, String districtName) {
    try {
      final geometry = geojsonData;
      
      if (geometry['type'] != 'Polygon') {
        return null;
      }

      final coordinates = geometry['coordinates'];
      
      if (coordinates == null || coordinates.isEmpty) {
        return null;
      }

      final outerRing = coordinates[0];
      
      final List<LatLng> points = [];

      for (int i = 0; i < outerRing.length; i++) {
        final coord = outerRing[i];
        if (coord is List && coord.length >= 2) {
          final lng = coord[0].toDouble();
          final lat = coord[1].toDouble();
          points.add(LatLng(lat, lng));
        }
      }

      if (points.length < 3) {
        return null;
      }

      final polygon = Polygon(
        polygonId: PolygonId(districtName),
        points: points,
        strokeWidth: 2,
        strokeColor: Color(0xFFFF002B),
        fillColor: Color(0xFFFF002B).withOpacity(0.2),
      );
      
      return polygon;
    } catch (e) {
      return null;
    }
  }

  LatLng _calculatePolygonCenter(List<LatLng> points) {
    if (points.isEmpty) {
      return LatLng(37.5665, 126.9780);
    }
    
    double sumLat = 0.0;
    double sumLng = 0.0;
    
    for (final point in points) {
      sumLat += point.latitude;
      sumLng += point.longitude;
    }
    
    return LatLng(sumLat / points.length, sumLng / points.length);
  }

  void _moveMapToPolygon(List<LatLng> points) {
    if (points.isEmpty) return;
    
    final center = _calculatePolygonCenter(points);
    
    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;
    
    for (final point in points) {
      minLat = min(minLat, point.latitude);
      maxLat = max(maxLat, point.latitude);
      minLng = min(minLng, point.longitude);
      maxLng = max(maxLng, point.longitude);
    }
    
    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
    
    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 50.0),
    );
  }

  void _clearAllMarkers() {
    setState(() {
      _markers = {};
      _polygons = {};
    });
  }

  void _adjustMapCenter(List<Map<String, dynamic>> districts) {
    if (districts.isEmpty) return;
    
    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;
    
    for (final district in districts) {
      final coordinates = district['coordinates'];
      if (coordinates != null) {
        final lat = coordinates['lat']?.toDouble() ?? 0.0;
        final lng = coordinates['lng']?.toDouble() ?? 0.0;
        
        if (lat != 0.0 && lng != 0.0) {
          minLat = min(minLat, lat);
          maxLat = max(maxLat, lat);
          minLng = min(minLng, lng);
          maxLng = max(maxLng, lng);
        }
      }
    }
    
    if (minLat != double.infinity) {
      final centerLat = (minLat + maxLat) / 2;
      final centerLng = (minLng + maxLng) / 2;
      
      setState(() {
        _center = LatLng(centerLat, centerLng);
      });
      
      _mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat, minLng),
            northeast: LatLng(maxLat, maxLng),
          ),
          50.0,
        ),
      );
    }
  }

  Future<void> _searchDistricts(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final url = '${ApiConfig.baseUrl}/api/regions/${widget.provinceId}/districts/search?query=${Uri.encodeComponent(query)}';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true && data['data'] != null) {
          final results = List<Map<String, dynamic>>.from(data['data']);
          
          setState(() {
            _searchResults = results;
          });
        } else {
          setState(() {
            _searchResults = [];
          });
        }
      } else {
        setState(() {
          _searchResults = [];
        });
      }
    } catch (e) {
      setState(() {
        _searchResults = [];
      });
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _onSearchChanged() {
    if (_isSelectingFromAutocomplete) {
      return;
    }
    
    final query = _searchController.text.trim();
    
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _selectedDistrictId = null;
        _selectedDistrictName = null;
      });
      _clearAllMarkers();
    } else {
      _searchDistricts(query);
    }
  }

  void _selectDistrict(Map<String, dynamic> district) {
    _isSelectingFromAutocomplete = true;
    
    setState(() {
      _selectedDistrictId = district['regionId'];
      _selectedDistrictName = district['fullName'];
      _searchController.text = district['regionName'];
      _searchResults = [];
      _isSearching = false;
    });
    
    _addSelectedDistrictMarker(district);
    
    Future.delayed(Duration(milliseconds: 100), () {
      _isSelectingFromAutocomplete = false;
    });
  }

  void _onComplete() {
    if (_selectedDistrictId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('행정동을 선택해주세요')),
      );
      return;
    }

    widget.onDistrictSelected(_selectedDistrictName!);
    Navigator.pop(context);
  }

  Widget _buildMap() {
    return Container(
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            GoogleMap(
              mapType: MapType.normal,
              initialCameraPosition: CameraPosition(
                target: _center,
                zoom: _zoom,
              ),
              onMapCreated: (controller) {
                _mapController = controller;
              },
              markers: _markers,
              polygons: _polygons,
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              onTap: (LatLng latLng) {
                setState(() {
                  _selectedDistrictId = null;
                  _selectedDistrictName = null;
                  _searchController.clear();
                  _searchResults = [];
                });
                _clearAllMarkers();
              },
            ),
            
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: '행정동을 검색해주세요 (예: 봉천동, 신림동)',
                        prefixIcon: Icon(Icons.search),
                        suffixIcon: _isSearching 
                            ? Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                                  ),
                                ),
                              )
                            : _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchResults = [];
                                        _isSearching = false;
                                        _selectedDistrictId = null;
                                        _selectedDistrictName = null;
                                      });
                                      _clearAllMarkers();
                                    },
                                  )
                                : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    
                    if (_searchResults.isNotEmpty)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                          border: Border(
                            top: BorderSide(color: Colors.grey.shade200),
                          ),
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _searchResults.length > 5 ? 5 : _searchResults.length,
                          itemBuilder: (context, index) {
                            final district = _searchResults[index];
                            return ListTile(
                              dense: true,
                              title: Text(
                                district['regionName'],
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Text(
                                district['fullName'],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              onTap: () => _selectDistrict(district),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompleteButton() {
    return Container(
      margin: EdgeInsets.fromLTRB(16, 16, 16, 24),
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _selectedDistrictId != null ? _onComplete : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _selectedDistrictId != null 
              ? Color(0xFFFF002B) 
              : Colors.grey.shade300,
          foregroundColor: _selectedDistrictId != null 
              ? Colors.white 
              : Colors.grey.shade600,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Text(
          '완료',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '지역 선택',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(child: _buildMap()),
                _buildCompleteButton(),
              ],
            ),
            if (_isLoadingDistricts)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: Center(
                  child: Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF002B)),
                        ),
                        SizedBox(height: 16),
                        Text(
                          '행정동 정보를 불러오는 중...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}