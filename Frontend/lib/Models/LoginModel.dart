// No Statement Management
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:Frontend/Login/kakaoLoginAbstract.dart';

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
    isLogined = false;
    user = null;
  }
}