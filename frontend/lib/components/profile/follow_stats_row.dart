import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 팔로워/팔로잉 통계 표시 위젯
/// 
/// 사용처: MyProfileScreen, UserProfileScreen
/// 
/// 사용 예시:
/// ```dart
/// FollowStatsRow(
///   username: 'username',
///   followersCount: 100,
///   followingCount: 50,
///   isMyProfile: true,  // 내 프로필이면 /me/followers, 아니면 /user/{username}/followers
///   showActivityRegion: true,
///   activityRegionName: '서울특별시 관악구',
/// )
/// ```
class FollowStatsRow extends StatelessWidget {
  /// 사용자 username (라우팅용)
  final String username;
  
  /// 팔로워 수
  final int followersCount;
  
  /// 팔로잉 수
  final int followingCount;
  
  /// 내 프로필 여부 (라우팅 경로 결정)
  final bool isMyProfile;
  
  /// 활동 지역 표시 여부
  final bool showActivityRegion;
  
  /// 활동 지역 이름
  final String? activityRegionName;
  
  /// 팔로우 리스트 화면에서 돌아왔을 때 호출될 콜백
  final VoidCallback? onReturn;

  const FollowStatsRow({
    Key? key,
    required this.username,
    required this.followersCount,
    required this.followingCount,
    this.isMyProfile = false,
    this.showActivityRegion = false,
    this.activityRegionName,
    this.onReturn,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String followersRoute = isMyProfile 
        ? '/me/followers' 
        : '/user/$username/followers';
    final String followingRoute = isMyProfile 
        ? '/me/following' 
        : '/user/$username/following';

    return Row(
      children: [
        // 팔로워
        GestureDetector(
          onTap: () async {
            await context.push(followersRoute);
            onReturn?.call();
          },
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '팔로워 ',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                TextSpan(
                  text: '$followersCount',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(width: 8),
        const Text(
          '·',
          style: TextStyle(
            fontSize: 16,
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        
        // 팔로잉
        GestureDetector(
          onTap: () async {
            await context.push(followingRoute);
            onReturn?.call();
          },
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '팔로잉 ',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                TextSpan(
                  text: '$followingCount',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // 활동 지역 (선택)
        if (showActivityRegion && activityRegionName != null) ...[
          const SizedBox(width: 8),
          const Text(
            '·',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            activityRegionName!,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }
}

