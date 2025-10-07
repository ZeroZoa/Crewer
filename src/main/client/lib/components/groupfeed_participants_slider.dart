import 'package:flutter/material.dart';

class GroupfeedParticipantsSlider extends StatefulWidget {
  final int maxParticipants;
  final Function(int) onParticipantsChanged; 
  const GroupfeedParticipantsSlider({super.key, required this.maxParticipants,required this.onParticipantsChanged});
  

  @override
  State<GroupfeedParticipantsSlider> createState() => _GroupFeedParticipantsSliderState();
}

class _GroupFeedParticipantsSliderState extends State<GroupfeedParticipantsSlider> {
  late int _maxParticipants;
  @override
  void initState() {
    super.initState();
    // 💡 2. initState에서 부모로부터 받은 final 값을 State 변수로 복사합니다.
    _maxParticipants = widget.maxParticipants;
  }

  @override
 Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return AnimatedPadding(
      padding: EdgeInsets.only(bottom: bottomInset),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      child: FractionallySizedBox(
        heightFactor: 0.25, // 키보드가 올라오면 높이를 늘림
        alignment: bottomInset > 0 ? Alignment.topCenter : Alignment.bottomCenter, // 키보드가 올라오면 상단 정렬
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(            
            mainAxisSize: MainAxisSize.min,
            children: [                                        
                   Text('모집 인원 설정', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold) ),
                  Slider(
                    value: _maxParticipants.toDouble(),
                    min: 2,
                    max: 10,
                    divisions: 8,
                    label: '$_maxParticipants명',
                    onChanged: (v) => setState(() => _maxParticipants = v.toInt()),
                    activeColor: const Color(0xffFF002B),
                    inactiveColor: Color(0xffEEEEEE),
                    thumbColor: const Color(0xffFF002B),
                  ),

              const SizedBox(height: 20),
              
              // 완료 버튼
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: (){Navigator.pop(context);
                  widget.onParticipantsChanged(_maxParticipants); },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF2B2D42),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                          '완료',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),              
            ],
          ),
        ),
      ),
    );
  }
  }