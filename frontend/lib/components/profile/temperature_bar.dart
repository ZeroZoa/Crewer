import 'package:flutter/material.dart';

/// 온도 표시 바 위젯 (애니메이션 포함)
/// 
/// 사용처: MyProfileScreen, UserProfileScreen
/// 
/// 사용 예시:
/// ```dart
/// TemperatureBar(
///   temperature: 38.5,
///   animate: true,
///   animationDuration: Duration(seconds: 2),
/// )
/// ```
class TemperatureBar extends StatefulWidget {
  /// 표시할 온도 값
  final double temperature;
  
  /// 애니메이션 활성화 여부
  final bool animate;
  
  /// 애니메이션 시간
  final Duration animationDuration;
  
  /// 바 높이
  final double barHeight;

  const TemperatureBar({
    Key? key,
    required this.temperature,
    this.animate = true,
    this.animationDuration = const Duration(seconds: 2),
    this.barHeight = 16.0,
  }) : super(key: key);

  @override
  State<TemperatureBar> createState() => _TemperatureBarState();
}

class _TemperatureBarState extends State<TemperatureBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    
    if (widget.animate) {
      _controller = AnimationController(
        vsync: this,
        duration: widget.animationDuration,
      );
      
      _animation = Tween<double>(
        begin: 0,
        end: widget.temperature,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ));
      
      _controller.forward();
    } else {
      // 애니메이션 없으면 더미 컨트롤러
      _controller = AnimationController(vsync: this);
      _animation = AlwaysStoppedAnimation(widget.temperature);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '온도 : ${_animation.value.toStringAsFixed(1)}°C',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: widget.barHeight,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _animation.value / 100,
                  backgroundColor: Colors.transparent,
                  color: const Color(0xFFFF002B),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

