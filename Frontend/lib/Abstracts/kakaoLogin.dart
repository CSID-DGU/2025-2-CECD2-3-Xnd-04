import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:Frontend/Abstracts/kakaoLoginAbstract.dart';
import 'package:Frontend/Services/authService.dart';

bool isTokenResponsed = false;
// 카카오톡 로그인 버전(카카오 계정 로그인 X)
class KakaoLogin implements SocialLogin {
  @override
  Future<bool> login() async {
    print('🚀 KakaoLogin.login() 함수 시작');
    try {
      OAuthToken token;

      // 카카오톡 설치 여부와 관계없이 항상 웹 로그인 시도
      try {
        print('🌐 웹 브라우저로 카카오 로그인을 진행합니다.');
        token = await UserApi.instance.loginWithKakaoAccount();
        print('🎉 loginWithKakaoAccount 성공');
      } catch (e) {
        print('❌ 카카오 웹 로그인 실패: $e');
        return false;
      }

      print('✅ 카카오 OAuth 토큰 발급 성공');
      print('🔑 카카오 액세스 토큰: ${token.accessToken}');

      print('📤 서버로 토큰 전송 시작...');
      isTokenResponsed = await sendKakaoAccessToken(token.accessToken);
      print("📥 토큰 서버 전송 결과: $isTokenResponsed");
      print('✅ 토큰 생성 완료');
      return isTokenResponsed;

    } catch (e) {
      print('❌ 카카오 로그인 실패 (전체 프로세스): $e');
      print('❌ 에러 타입: ${e.runtimeType}');
      print('❌ 스택 트레이스: ${StackTrace.current}');
      return false;
    }
  }

  @override
  Future<bool> logout() async {
    try {
      await UserApi.instance.unlink();
      return true;
    } catch (error) {
      return false;
    }
  }
}

