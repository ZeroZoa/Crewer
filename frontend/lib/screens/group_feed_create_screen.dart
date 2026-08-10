import 'package:client/components/groupfeed_participants_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:go_router/go_router.dart';
import 'package:client/components/login_modal_screen.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../components/custom_app_bar.dart';
import '../config/api_config.dart';
import 'place_picker_screen.dart';

/// 그룹 피드 작성 화면
class GroupFeedCreateScreen extends StatefulWidget {
  const GroupFeedCreateScreen({Key? key}) : super(key: key);

  @override
  _GroupFeedCreateScreenState createState() => _GroupFeedCreateScreenState();
}

class _GroupFeedCreateScreenState extends State<GroupFeedCreateScreen> {
  bool _isSubmitting = false;
  int _maxParticipants = 2;

  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  final TextEditingController _meetingPlaceController = TextEditingController();
  DateTime? _deadline;
  double? _selectedLatitude;
  double? _selectedLongitude;
  bool _isfilled = false;
  bool _isCreateComplete = false;
  late var _newGroupFeedId;

  final String _tokenKey = 'token';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _contentController = TextEditingController();
    
    _titleController.addListener(_checkFields);
    _contentController.addListener(_checkFields);
    _checkLogin();
  }
   
  void _checkFields(){   
    if(_titleController.text.trim().isNotEmpty && _contentController.text.trim().isNotEmpty){
      setState(() {
      _isfilled = true;
    });
    }else{
       setState(() {
      _isfilled = false;
    });
    } 
  }

  Future<void> _checkLogin() async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null) {
      // 로그인 모달 표시
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => LoginModalScreen(),
      );

      // 모달 닫힌 뒤에도 여전히 비로그인 상태라면 이전 화면으로 돌아감
      final newToken = await _storage.read(key: _tokenKey);

      if (newToken == null) {
        context.pop();
      }
    }
  }

  void _showLoginModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => LoginModalScreen(),
    );
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

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final token = await _storage.read(key: _tokenKey);

    if (token == null) {
      _showLoginModal();
      setState(() => _isSubmitting = false);
      return;
    }

    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getGroupFeedCreate()}');
    final body = json.encode({
      'title': _titleController.text.trim(),
      'content': _contentController.text.trim(),
      'maxParticipants': _maxParticipants,
      'meetingPlace': _meetingPlaceController.text.trim(),
      'latitude': _selectedLatitude,
      'longitude': _selectedLongitude,
      'deadline': _deadline?.toUtc().toIso8601String(),
    });

    try {
      final resp = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final data = json.decode(resp.body);
        final newGroupFeedId = data['id'];
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('그룹 피드 작성이 완료되었습니다!')),
          );
             setState(() {
            _newGroupFeedId = newGroupFeedId;
            _isCreateComplete = true;
          });
        });
      } else {
        final errorText = resp.body;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('작성 실패'),
              content: Text(errorText),
              actions: [
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('확인'),
                ),
              ],
            ),
          );
        });
      }
    } catch (_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('서버 오류'),
            content: const Text('서버 오류가 발생했습니다.'),
            actions: [
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('확인'),
              ),
            ],
          ),
        );
      });
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _showMaxParticipantsSlider() async {
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
    if(_isCreateComplete){
      return Scaffold(
        appBar: CustomAppBar(
        appBarType: AppBarType.close,
        title: Padding(
          // IconButton의 기본 여백과 비슷한 값을 줍니다.
          padding: const EdgeInsets.only(left: 0, top: 4),
          child: Text(
            '게시글 작성 완료',
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
                "작성이 완료되었습니다",
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
                final route = '/groupfeeds/${_newGroupFeedId}';
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
            '그룹 피드 게시글',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 22,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => {},            
            style: TextButton.styleFrom(foregroundColor: Color(0xFFBDBDBD)),
            child: Text("임시저장")
            )
        ],
      ),
        body: SingleChildScrollView( // 키보드가 올라올 때 UI가 밀리는 것을 방지
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Container(            
            decoration: BoxDecoration(
              color: Color(0xFFFAFAFA),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
                children: [
                  TextField(
                    controller: _titleController,
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold
                    ),
                    decoration: InputDecoration(
                      labelText: '제목을 입력해주세요.',
                      labelStyle: TextStyle(
                        color: Color(0xFF767676),
                        fontSize: 21,
                        fontWeight: FontWeight.bold
                      ),
                      floatingLabelStyle: TextStyle(
                        color: Color(0xFF767676),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFF767676), width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),                    
                  ),
                  const SizedBox(height: 3),
                  const Divider(color: Color(0xFFDBDBDB)),
                  TextButton(
                    onPressed: _selectPlaceFromMap,
                    child : Row(
                      children: [
                        Icon(LucideIcons.mapPin,
                          color: _meetingPlaceController.text.isEmpty
                              ? const Color(0xff999999)
                              : const Color(0xffFF002B),
                        ),
                        Flexible(
                          child: Text(_meetingPlaceController.text.isEmpty
                              ? "장소 추가"
                              :_meetingPlaceController.text.length > 15
                              ?_meetingPlaceController.text.substring(0,15)+'..'
                              :_meetingPlaceController.text,
                            style: TextStyle(color: _meetingPlaceController.text.isEmpty
                                ? const Color(0xff999999)
                                : const Color(0xffFF002B)),),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _showMaxParticipantsSlider,
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
                  const SizedBox(height: 3),
                  const Divider(color: Color(0xFFDBDBDB)),
                 SizedBox(
                  height: 530,
                    child: TextField(
                      controller: _contentController,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: InputDecoration(
                        labelText: '게시글 내용을 입력해주세요.',
                           labelStyle: TextStyle(
                        color: Color(0xFF767676),
                        fontSize: 17
                      ),
                      floatingLabelStyle: TextStyle(
                        color: Color(0xFF767676),
                      ),
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
              onPressed: _handleSubmit,
              style: ElevatedButton.styleFrom(
                
                backgroundColor: _isfilled ? Color(0xFFFF002B):const Color(0xFFBDBDBD),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                  _isSubmitting ? '작성 중...' : '작성 완료',
                  style: TextStyle(fontSize: 16,)
              ),
            ),
          ),
        ),
      ),
    );
  }
}
