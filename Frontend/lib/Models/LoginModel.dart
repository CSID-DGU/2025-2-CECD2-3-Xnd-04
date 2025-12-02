// No Statement Management
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:Frontend/Abstracts/kakaoLoginAbstract.dart';
import 'package:Frontend/Services/authService.dart';

class LoginModel{
  final SocialLogin _socialLogin;
  bool isLogined = false;
  User? user;     //Nullable

  LoginModel(this._socialLogin);

  Future login() async {
    print('📱 LoginModel.login() 호출됨');
    isLogined = await _socialLogin.login();
    print('📱 _socialLogin.login() 결과: $isLogined');
    if (isLogined) {
      user = await UserApi.instance.me();
      print('📱 사용자 정보 가져오기 성공');
    } else {
      print('📱 로그인 실패 - isLogined = false');
    }
  }

  Future logout() async {
    await _socialLogin.logout();
    await clearTokens(); // 저장된 토큰 삭제
    isLogined = false;
    user = null;
  }
}