import 'package:Frontend/nativeAppKey.dart';
import 'package:flutter/material.dart';
import 'package:Frontend/Views/LoginView.dart';
import 'package:Frontend/Views/MainFrameView.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

void main() {
  KakaoSdk.init(nativeAppKey: nativeAppKey);
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
        '/InitialHomeView' : (context) => pages[0],
        '/IngredientsView' : (context) => pages[1],
        '/RecipeView' : (context) => pages[2],
        '/FavoritesView' : (context) => pages[3],
        '/CartView' : (context) => pages[4],
        '/HomeView' : (context) => pages[5],
        '/IngredientsInfoView' : (context) => pages[6],
        '/AlertView' : (context) => pages[7],
        '/SettingView' : (context) => pages[8],
      }
    );
  }
}

// URL : https://github.com/junsuk5/flutter-kakao-login-guide/blob/master/lib/main.dart