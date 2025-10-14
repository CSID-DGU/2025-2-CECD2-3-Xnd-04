  import 'package:flutter/material.dart';
import 'package:Frontend/Views/LoginView.dart';
import 'package:Frontend/Views/MainFrameView.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:Frontend/PushService/fcmService.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');
  final kakaoAppKey = dotenv.env['KAKAO_APP_KEY'];
  KakaoSdk.init(nativeAppKey: kakaoAppKey);

  // FCM 초기화
  await FCMService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(

      title: 'Bespoke',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const LoginView(),
      routes: {
        //초기 냉장고 추가 뷰
        '/InitialHomeView' : (context) => pages[0],
        //냉장고 내부 뷰
        '/IngredientsView' : (context) => pages[1],
        //레시피 뷰
        '/RecipeView' : (context) => pages[2],
        //즐겨찾기 뷰
        '/FavoritesView' : (context) => pages[3],
        //장바구니 뷰
        '/CartView' : (context) => pages[4],
        //홈 뷰
        '/HomeView' : (context) => pages[5],
        //식재료 정보 뷰
        '/IngredientsInfoView' : (context) => pages[6],
        //냉장고 속 식재료 정보 뷰
        '/FridgeIngredientsInfoView' : (context) => pages[7],
        //알림 뷰
        '/AlertView' : (context) => pages[8],
        //설정 뷰
        '/SettingView' : (context) => pages[9],
        //가계부 뷰
        '/AccountBookView' : (context) => pages[10],
        //검색 뷰
        '/SearchView' : (context) => pages[11],
      }
    );
  }
}

// URL : https://github.com/junsuk5/flutter-kakao-login-guide/blob/master/lib/main.dart