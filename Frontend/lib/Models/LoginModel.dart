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
    isLogined = await _socialLogin.login();
    if (isLogined) {
      user = await UserApi.instance.me();
    }
  }

  Future logout() async {
    await _socialLogin.logout();
    await clearTokens(); // 저장된 토큰 삭제
    isLogined = false;
    user = null;
  }
}