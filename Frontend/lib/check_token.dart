import 'package:flutter/material.dart';
import 'package:Frontend/Services/authService.dart';

/// 토큰 확인용 간단한 앱
/// 실행 방법: flutter run lib/check_token.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TokenCheckerApp());
}

class TokenCheckerApp extends StatelessWidget {
  const TokenCheckerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: TokenCheckerScreen(),
    );
  }
}

class TokenCheckerScreen extends StatefulWidget {
  @override
  State<TokenCheckerScreen> createState() => _TokenCheckerScreenState();
}

class _TokenCheckerScreenState extends State<TokenCheckerScreen> {
  String _accessToken = '확인 중...';
  String _refreshToken = '확인 중...';
  String _isLoggedIn = '확인 중...';

  @override
  void initState() {
    super.initState();
    _checkTokens();
  }

  Future<void> _checkTokens() async {
    try {
      // 저장된 토큰 확인
      final tokens = await getSavedTokens();
      final loggedIn = await isLoggedIn();

      setState(() {
        _accessToken = tokens['access_token'] ?? '❌ 없음';
        _refreshToken = tokens['refresh_token'] ?? '❌ 없음';
        _isLoggedIn = loggedIn ? '✅ 로그인됨' : '❌ 로그인 안됨';
      });
    } catch (e) {
      setState(() {
        _accessToken = '오류: $e';
        _refreshToken = '오류: $e';
        _isLoggedIn = '오류: $e';
      });
    }
  }

  Future<void> _clearTokens() async {
    await clearTokens();
    _checkTokens();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('토큰이 삭제되었습니다')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('JWT 토큰 확인'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '로그인 상태',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(_isLoggedIn),
            SizedBox(height: 24),
            Text(
              'Access Token',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            SelectableText(
              _accessToken,
              style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
            ),
            SizedBox(height: 24),
            Text(
              'Refresh Token',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            SelectableText(
              _refreshToken,
              style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
            ),
            SizedBox(height: 32),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _checkTokens,
                  child: Text('토큰 다시 확인'),
                ),
                SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _clearTokens,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: Text('토큰 삭제'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
