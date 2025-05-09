import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:Frontend/Abstracts/kakaoLoginAbstract.dart';

// 카카오톡 로그인 버전(카카오 계정 로그인 X)
class KakaoLogin implements SocialLogin {
  @override
  Future<bool> login() async {
    try {
      bool isInstalled = await isKakaoTalkInstalled();

      OAuthToken token;

      if (isInstalled) {
        try {
          token = await UserApi.instance.loginWithKakaoTalk();
          print('accessToken: ${token.accessToken}');
          print('refreshToken: ${token.refreshToken}');
          return true;
        } catch (e) {
          print('카카오톡 앱 내에서 로그인 부탁드립니다. $e');
          return false;
        }
      } else {
        try {
          token = await UserApi.instance.loginWithKakaoAccount();
          print('accessToken: ${token.accessToken}');
          print('refreshToken: ${token.refreshToken}');
          return true;
        } catch (e) {
          print('카카오톡 계정을 생성하거나 앱 설치 후 로그인을 해주세요 : $e');
          return false;
        }
      }
    } catch (e) {
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

