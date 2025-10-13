import 'package:flutter/material.dart';
import 'package:Frontend/Widgets/CommonAppBar.dart';
import 'package:Frontend/Views/MainFrameView.dart';

/// 공통 레이아웃 위젯
/// 상단바와 하단바를 고정하고, body 영역만 스크롤 가능하도록 구성
class CommonLayout extends StatelessWidget {
  final Widget body;
  final String title;
  final bool showBackButton;
  final bool showBottomNav;

  const CommonLayout({
    Key? key,
    required this.body,
    this.title = 'Xnd',
    this.showBackButton = false,
    this.showBottomNav = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color(0xFF2196F3),
    appBar: CommonAppBar(
      title: title,
    ),
    body: body,
    bottomNavigationBar: showBottomNav ? const MainBottomView() : null,
  );
  }
}
