import 'package:client/components/groupfeed_participants_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:client/components/login_modal_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../config/api_config.dart';
import '../components/custom_app_bar.dart';

/// 그룹 피드 수정 화면
class GroupFeedEditScreen extends StatefulWidget {
  final String groupFeedId;
  const GroupFeedEditScreen({Key? key, required this.groupFeedId}) : super(key: key);

  @override
  _GroupFeedEditScreenState createState() => _GroupFeedEditScreenState();
}

class _GroupFeedEditScreenState extends State<GroupFeedEditScreen> {
  int _maxParticipants = 2;
  bool _loading = true;
  bool _isSubmitting = false;
  bool _isEditComplete = false;
  late var _editGroupFeedId;
  double? _selectedLatitude;
  double? _selectedLongitude;
  DateTime? _deadline;

  final String _tokenKey = 'token';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _meetingPlaceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkLoginAndFetch();
  }

  Future<void> _checkLoginAndFetch() async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showLoginModal());
      return;
    }
    try {
      final resp = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getGroupFeedEdit(widget.groupFeedId)}'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        _titleController.text = data['title'] ?? '';
        _contentController.text = data['content'] ?? '';
        _selectedLatitude = data['latitude'] ?? '';
        _selectedLongitude = data['longitude'] ?? '';

        setState(() {
          _maxParticipants = data['maxParticipants'] ?? 2;
        _meetingPlaceController.text = data['meetingPlace'] ?? '';
        data['deadline'] != null && data['deadline'].isNotEmpty
        ? _deadline = DateTime.parse(data['deadline']).toLocal()
        :_deadline = null;
        });

      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('권한 오류'),
              content: const Text('게시글을 수정할 권한이 없습니다.'),
              actions: [
                TextButton(
                  onPressed: () {
                    context.replace('/groupfeeds/${widget.groupFeedId}');
                  },
                  child: const Text('확인'),
                ),
              ],
            ),
          );
        });
      }
    } catch (_) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.pop());
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showLoginModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => LoginModalScreen(),
    );
  }

  Future<void> _handleUpdate() async {
    if (_isSubmitting) return;
    if (_titleController.text.trim().isEmpty ||
        _contentController.text.trim().isEmpty ||
        _maxParticipants < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목, 내용, 최대 참가 인원을 입력하세요.')),
      );
      return;
    }
    setState(() => _isSubmitting = true);

    final token = await _storage.read(key: _tokenKey);

    if (token == null) {
      _showLoginModal();
      setState(() => _isSubmitting = false);
      return;
    }
    try {
      final resp = await http.put(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getGroupFeedEdit(widget.groupFeedId)}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'title': _titleController.text.trim(),
          'content': _contentController.text.trim(),
          'maxParticipants': _maxParticipants,
          'meetingPlace': _meetingPlaceController.text.trim(),
          'latitude': _selectedLatitude,
          'longitude': _selectedLongitude,
          'deadline': _deadline?.toUtc().toIso8601String(),
        }),
      );
      if (resp.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('그룹 피드가 수정되었습니다.')),
        );
        final data = json.decode(resp.body);
        final editGroupFeedId = data['id'];
         setState(() {
            _editGroupFeedId = editGroupFeedId;
            _isEditComplete = true;
          });
      } else {
        final errorText = resp.body;
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('수정 실패'),
            content: Text(errorText),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('확인'),
              ),
            ],
          ),
        );
      }
    } catch (_) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('서버 오류'),
          content: const Text('서버 오류가 발생했습니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('확인'),
            ),
          ],
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }
  Future<void> _selectDeadline(BuildContext context) async {
    // 날짜 선택
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );

    if (pickedDate == null) return; // 날짜 선택 취소

    // 시간 선택
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(DateTime.now()),
    );

    if (pickedTime == null) return; // 시간 선택 취소

    // 선택된 날짜와 시간을 합쳐서 상태 업데이트
    setState(() {
      _deadline = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }
    Future<void> _selectMaxParticipants() async {
     showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => GroupfeedParticipantsSlider(maxParticipants: _maxParticipants,
      onParticipantsChanged: (maxParticipants) {
            setState(() {
              _maxParticipants = maxParticipants;
            });
          }),
          );
  }

  Future<void> _selectPlaceFromMap() async {
    final result = await context.push('/place-picker');
    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _meetingPlaceController.text = result['address'];
        _selectedLatitude = result['latitude']?.toDouble();
        _selectedLongitude = result['longitude']?.toDouble();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
     if(_isEditComplete){
      return Scaffold(
        appBar: CustomAppBar(
        appBarType: AppBarType.close,
        title: Padding(
          // IconButton의 기본 여백과 비슷한 값을 줍니다.
          padding: const EdgeInsets.only(left: 0, top: 4),
          child: Text(
            '게시글 수정 완료',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 22,
            ),
          ),
        ),
      ),
      backgroundColor: Color(0xFFFAFAFA),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 250,
                child: Image.asset('assets/images/check.jpg')),
              SizedBox(height: 30,),
              Text(
                "수정이 완료되었습니다",
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold),),
            ],
          )
          ),
          bottomNavigationBar:  SafeArea(                                    
        child: Container(
          height: 100,
          decoration: BoxDecoration( color: Colors.white),                                      
          padding: const EdgeInsets.symmetric(horizontal: 20,vertical: 20),
          child:  SizedBox(
            height: 20,
            child: ElevatedButton(
              onPressed:() {
                final route = '/groupfeeds/${_editGroupFeedId}';
                context.replace(route);
              },
              style: ElevatedButton.styleFrom(                
                backgroundColor: Color(0xFFFF002B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                  '게시글 보러가기',
                  style: TextStyle(fontSize: 16,)
              ),
            ),
          ),
        ),
      ),
        );
     }
    return Scaffold(
      appBar: CustomAppBar(
        appBarType: AppBarType.close,
        title: Padding(
          // IconButton의 기본 여백과 비슷한 값을 줍니다.
          padding: const EdgeInsets.only(left: 0, top: 4),
          child: Text(
            '그룹피드 수정',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 22,
            ),
          ),
        ),
        actions: [],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Container(
            decoration: BoxDecoration(
              color: Color(0xFFFAFAFA),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                 TextField(
                    controller: _titleController,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold
                    ),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF767676), width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),                    
                  ),
                const SizedBox(height: 3),
                const Divider(color: Color(0xFFDBDBDB)),
                Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                    TextButton(
                      onPressed: _selectPlaceFromMap,
                         child : Row(
                          mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.mapPin,
                          color: _meetingPlaceController.text.isEmpty
                          ? const Color(0xff999999)
                          : const Color(0xffFF002B)
                          ,),
                           Flexible(
                             child: Text(
                              _meetingPlaceController.text.isEmpty
                              ? "장소 추가"
                              :_meetingPlaceController.text.length>5
                                ?_meetingPlaceController.text.substring(0,6)+'..'
                                :_meetingPlaceController.text,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: _meetingPlaceController.text.isEmpty
                              ? const Color(0xff999999)
                              : const Color(0xffFF002B)),),
                           ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: _selectMaxParticipants,
                         child : Row(
                        children: [
                          Icon(LucideIcons.user,
                            color:const Color(0xffFF002B)),
                          Text(' $_maxParticipants명',
                            style: TextStyle(color:const Color(0xffFF002B)),) ,
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () =>_selectDeadline(context),
                         child : Row(
                        children: [
                          Icon(LucideIcons.calendarClock,
                            color:_deadline==null
                            ?const Color(0xff999999)
                            :const Color(0xffFF002B)),
                          Text( _deadline == null
                          ? '마감 시간 설정'
                          // intl 패키지를 사용하여 날짜 포맷 지정
                          : DateFormat('yyyy년 MM월 dd일 HH:mm').format(_deadline!),
                            style: TextStyle( color:_deadline==null
                            ?const Color(0xff999999)
                            :const Color(0xffFF002B)),) ,
                        ],
                      ),
                    ),
                    ],
                  ),
                SizedBox(
                  height: 520,
                  child: TextField(
                    controller: _contentController,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: InputDecoration(                      
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF767676), width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar:  SafeArea(                                    
        child: Container(
          height: 100,
          decoration: BoxDecoration( color: Colors.white),                                      
          padding: const EdgeInsets.symmetric(horizontal: 20,vertical: 20),
          child:  SizedBox(
            height: 20,
            child: ElevatedButton(
              onPressed: _handleUpdate,
              style: ElevatedButton.styleFrom(                
                backgroundColor: Color(0xFFFF002B),
                // _isfilled ? Color(0xFFFF002B):const Color(0xFFBDBDBD),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                  _isSubmitting ? '작성 중...' : '수정 완료',
                  style: TextStyle(fontSize: 16,)
              ),
            ),
          ),
        ),
      ),
    );
  }
}
