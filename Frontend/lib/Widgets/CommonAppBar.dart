import 'package:flutter/material.dart';
import 'package:Frontend/Views/MainFrameView.dart';
import 'package:Frontend/Services/authService.dart';
import 'package:Frontend/Views/LoginView.dart';

/// 공통 AppBar 위젯
/// 모든 페이지에서 동일한 스타일의 상단바 사용
class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const CommonAppBar({
    Key? key,
    this.title = 'Xnd',
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(80);

  @override
  Widget build(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(80),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF2196F3),
        ),
        child: Column(
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              toolbarHeight: 56,
              automaticallyImplyLeading: false,
              elevation: 0,
              title: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w400,
                ),
              ),
              actions: [
                // 알림 버튼
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                  onPressed: () {
                    Navigator.of(context).pushNamed('/${pages[8]}');
                  },
                ),
                // 설정 버튼
                IconButton(
                  icon: const Icon(Icons.settings_outlined, color: Colors.white),
                  onPressed: () {
                    Navigator.of(context).pushNamed('/${pages[9]}');
                  },
                ),
                // 더보기 메뉴 (로그아웃)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onSelected: (String value) async {
                    if (value == 'logout') {
                      // 로그아웃 확인 다이얼로그
                      bool? confirmLogout = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('로그아웃'),
                          content: const Text('로그아웃 하시겠습니까?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('취소'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('로그아웃'),
                            ),
                          ],
                        ),
                      );

                      if (confirmLogout == true && context.mounted) {
                        // 토큰 삭제
                        await clearTokens();

                        // 로그인 페이지로 이동
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (context) => const LoginView()),
                          (route) => false,
                        );
                      }
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    return [
                      const PopupMenuItem<String>(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(Icons.logout, color: Colors.red),
                            SizedBox(width: 8),
                            Text('로그아웃', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ];
                  },
                ),
              ],
            ),
            // 하단에 body가 올라오는 곡선 영역
            Container(
              height: 24,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
