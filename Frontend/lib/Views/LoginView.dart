import 'package:flutter/material.dart';
import 'package:Frontend/Abstracts/kakaoLogin.dart';
import 'package:Frontend/Models/LoginModel.dart';
import 'package:Frontend/Models/RefrigeratorModel.dart';
import 'package:Frontend/Views/MainFrameView.dart';
import 'package:Frontend/Services/loadFridgeService.dart';
import 'package:Frontend/Services/authService.dart';
import 'package:Frontend/Services/loadFridgeIngredientInfoService.dart';

import '../PushService/fcmService.dart';

/* 남은 Task
1. 자동 로그인 시, 로그인을 스킵하는 기능 추가(데이터베이스에서 따와야됨)
*/

class LoginView extends StatefulWidget {
  const LoginView({Key? key}) : super(key: key);

  @override
  State<LoginView> createState() => LoginPage();
}

class LoginPage extends State<LoginView>{
  final loginViewModel = LoginModel(KakaoLogin());
  bool _isChecking = true; // 자동 로그인 체크 중

  @override
  void initState(){
    super.initState();
    _checkAutoLogin(); // 자동 로그인 체크
  }

  // 자동 로그인 확인
  Future<void> _checkAutoLogin() async {
    try {
      bool loggedIn = await isLoggedIn();

      if (loggedIn) {
        // 저장된 토큰 가져오기
        Map<String, String?> tokens = await getSavedTokens();
        if (tokens['access_token'] != null) {
          responsedAccessToken = tokens['access_token'];
          loginViewModel.isLogined = true;

          // FCM 기기 등록
          try {
            await FCMService.instance.registerDeviceToServer();
          } catch (e) {
            print('FCM 등록 실패: $e');
          }

          // 냉장고 정보 확인
          bool fridgeNonZero = false;
          try {
            fridgeNonZero = await getFridgesInfo();
          } catch (e) {
            print('냉장고 정보 로드 실패: $e');
            // 냉장고 정보 로드 실패 시 토큰이 만료되었을 수 있으므로 로그아웃
            await clearTokens();
            if (mounted) {
              setState(() {
                _isChecking = false;
              });
            }
            return;
          }

          if (mounted) {
            // 냉장고 유무에 따라 페이지 이동
            if (fridgeNonZero) {
              // 자동 로그인 시 식재료 정보도 함께 로드
              try {
                await loadFridgeIngredientsInfo(Fridges[0], 0);
              } catch (e) {
                print('자동 로그인: 식재료 정보 로드 실패 - $e');
              }

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (i) => pages[1]), // IngredientsView
              );
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (i) => pages[0]), // InitialHomeView
              );
            }
          }
          return;
        }
      }
    } catch (e) {
      print('자동 로그인 체크 실패: $e');
    }

    // 자동 로그인 실패 시 로그인 화면 표시
    if (mounted) {
      setState(() {
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    // 자동 로그인 체크 중일 때 로딩 화면 표시
    if (_isChecking) {
      return const Scaffold(
        backgroundColor: Color(0xFF2196F3),
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
      );
    }

    return Scaffold(
      // appBar: basicBar(),
      backgroundColor: const Color(0xFF2196F3), // 파란색 배경
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Xnd 텍스트
            const Text(
              'Xnd',
              style: TextStyle(
                fontSize: 48,
                color: Colors.white,
                fontWeight: FontWeight.w300,
              ),
            ),
            SizedBox(height: screenHeight * 0.08),
            // Smart Refrige 텍스트
            const Text(
              'Smart Refrige',
              style: TextStyle(
                fontSize: 32,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: screenHeight * 0.15),
            // 카카오 로그인 버튼
            SizedBox(
              width: screenWidth * 0.75,
              height: 55,
              child: ElevatedButton(
                onPressed: () async {
                  // 로그인 시, 로그인 여부 확인하고 냉장고의 수를 체크하여 냉장고 수에 따라 다른 화면으로 이동
                  await loginViewModel.login();

                  // 로그인 실패 시 리턴
                  if (!loginViewModel.isLogined) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('로그인에 실패했습니다. 다시 시도해주세요.')),
                      );
                    }
                    return;
                  }

                  // 🔥 FCM 기기 등록 (로그인 성공 후)
                  try {
                    await FCMService.instance.registerDeviceToServer();
                  } catch (e) {
                    print('FCM 등록 실패: $e');
                  }

                  // 냉장고 정보 가져오기
                  bool fridgeNonZero = false;
                  try {
                    fridgeNonZero = await getFridgesInfo();
                  } catch (e) {
                    print('냉장고 정보 로드 실패: $e');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('냉장고 정보를 불러오는데 실패했습니다.')),
                      );
                    }
                    return;
                  }

                  if (context.mounted) {
                    if (fridgeNonZero) {
                      // 카카오 로그인 시 식재료 정보도 함께 로드
                      try {
                        await loadFridgeIngredientsInfo(Fridges[0], 0);
                      } catch (e) {
                        print('카카오 로그인: 식재료 정보 로드 실패 - $e');
                      }

                      Navigator.push(context, MaterialPageRoute(builder: (i) => pages[1])); // IngredientsView
                    } else {
                      Navigator.push(context, MaterialPageRoute(builder: (i) => pages[0])); // InitialHomeView
                    }
                  }
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Image.asset('assets/images/kakaotalk_icon.png', width: 24, height: 24),
                    SizedBox(width: screenWidth * 0.02),
                    const Text(
                      '카카오 로그인',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFEB00), // 카카오 노란색
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
            // 네이버 로그인 버튼
            SizedBox(
              width: screenWidth * 0.75,
              height: 55,
              child: ElevatedButton(
                onPressed: () async {
                  // TODO: 네이버 로그인 기능 구현
                  print('네이버 로그인 버튼 클릭');
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    // 네이버 N 아이콘 (텍스트로 대체)
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Center(
                        child: Text(
                          'N',
                          style: TextStyle(
                            color: Color(0xFF03C75A),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.02),
                    const Text(
                      '네이버 로그인',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF03C75A), // 네이버 초록색
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
