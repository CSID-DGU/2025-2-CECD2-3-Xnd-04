import 'package:Frontend/nativeAppKey.dart';
import 'package:flutter/material.dart';
import 'package:Frontend/Views/LoginView.dart';
import 'package:Frontend/Views/MainFrameView.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:mysql_client/mysql_client.dart';

void main() {
  KakaoSdk.init(nativeAppKey: nativeAppKey);
  runApp(const MyApp());
}

Future<void> dbConnector() async {
  print("Connecting to mysql server...");

  // MySQL 접속 설정
  final conn = await MySQLConnection.createConnection(
    host: '127.0.0.1',
    port: 0000,
    userName: 'userName',
    password: 'password',
    databaseName: 'testdb', // optional
  );

  // 연결 대기
  try {
    print("Connecting...");
    await conn.connect();
  }
  catch(e){
    print('DB 연결 실패. 에러 로그${e}');
  }
  // 종료 대기
  await conn.close();
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
        '/AlertView' : (context) => pages[6],
        '/SettingView' : (context) => pages[7],
      }
    );
  }
}

// URL : https://github.com/junsuk5/flutter-kakao-login-guide/blob/master/lib/main.dart