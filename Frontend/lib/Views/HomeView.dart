import 'package:flutter/material.dart';
import 'package:Frontend/Views/MainFrameView.dart';
import 'package:Frontend/Views/IngredientsView.dart';
import 'package:Frontend/Models/RefrigeratorModel.dart';
import 'package:Frontend/Services/createFridgeService.dart';
import 'package:Frontend/Services/loadFridgeService.dart';
import 'package:Frontend/Services/loadFridgeIngredientInfoService.dart';
import 'package:Frontend/Widgets/CommonAppBar.dart';

bool isPlusButtonClicked = false;

class InitialHomeView extends StatefulWidget {
  const InitialHomeView({Key? key}) : super(key: key);

  @override
  State<InitialHomeView> createState() => InitialHomePage();
}

class InitialHomePage extends State<InitialHomeView> {
  int levelOfRefrigerator = 1;             // 냉장고 추가할 때 사용하는 변수
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _layerController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _layerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    // 냉장고가 0개인 경우 UI
    return Scaffold(
      // 냉장고 선택 페이지 UI
      appBar: const CommonAppBar(title: 'Xnd'),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SizedBox(height: screenHeight * 0.05),
              (!isPlusButtonClicked) ?

              Column(
                children: [
                Container(
                  width: screenWidth * 0.4,
                  height: screenWidth * 0.4,
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: () async {
                      setState(() {
                        isPlusButtonClicked = true;
                      });
                    },
                    icon: const Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 80,
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.03),
                const Text(
                  '냉장고를 등록해주세요',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.black54,
                  ),
                ),
              ],
            )
                :

            // 냉장고 정보 입력 폼
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '냉장고 정보 입력',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.05),

                  // 냉장고 이름 입력
                  const Text(
                    '냉장고 이름',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  TextField(
                    controller: _nameController,
                    maxLength: 10,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      hintText: '이름을 입력하세요',
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      suffixIcon: _nameController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: () {
                                setState(() {
                                  _nameController.clear();
                                });
                              },
                            )
                          : null,
                    ),
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                  SizedBox(height: screenHeight * 0.03),

                  // 냉장고 단수 입력
                  const Text(
                    '냉장고 단수',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  TextField(
                    controller: _layerController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: '0',
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      suffixIcon: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          InkWell(
                            onTap: () {
                              int currentValue = int.tryParse(_layerController.text) ?? 0;
                              _layerController.text = (currentValue + 1).toString();
                            },
                            child: const Icon(Icons.arrow_drop_up, size: 24),
                          ),
                          InkWell(
                            onTap: () {
                              int currentValue = int.tryParse(_layerController.text) ?? 0;
                              if (currentValue > 0) {
                                _layerController.text = (currentValue - 1).toString();
                              }
                            },
                            child: const Icon(Icons.arrow_drop_down, size: 24),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.05),

                  // 저장/취소 버튼
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            // 취소 버튼 - 이전 페이지로
                            setState(() {
                              isPlusButtonClicked = false;
                              _nameController.clear();
                              _layerController.clear();
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF2196F3),
                            padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: Color(0xFF2196F3), width: 1),
                            ),
                          ),
                          child: const Text(
                            '취소',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.04),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            // 저장 버튼 - 서버로 전송
                            String fridgeName = _nameController.text.trim();
                            int? layerCount = int.tryParse(_layerController.text);

                            // 냉장고 단수 유효성 검사
                            if (layerCount == null || layerCount <= 0) {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('입력 오류'),
                                  content: const Text('냉장고 단수는 1이상이어야 합니다!'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      child: const Text('확인'),
                                    ),
                                  ],
                                ),
                              );
                              return;
                            }

                            // 냉장고 이름이 없으면 기본값 사용
                            if (fridgeName.isEmpty) {
                              int fridgeNumber = (numOfFridge ?? 0) + 1;
                              fridgeName = '$fridgeNumber번 냉장고';
                            }

                            // 서버로 전송
                            bool sendCreateToServer = await createFridgeToServer(
                              refrigerator: RefrigeratorModel(
                                level: layerCount,
                                label: fridgeName,
                              )
                            );

                            if (!mounted) return;

                            if (sendCreateToServer) {
                              bool isArrivedFridgesInfo = await getFridgesInfo();

                              if (!mounted) return;

                              if (isArrivedFridgesInfo) {
                                setState(() {
                                  pages[1] = IngredientsView(refrigerator: Fridges[0]);
                                  isPlusButtonClicked = false;
                                  _nameController.clear();
                                  _layerController.clear();
                                });
                                Navigator.of(context).pushNamed('/${pages[5]}');
                              } else {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('냉장고 정보 수령 불가'),
                                    content: const Text('서버 오류로 인해 냉장고를 로드할 수 없습니다.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(),
                                        child: const Text('돌아가기'),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            } else {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('서버 요청 불가'),
                                  content: const Text('서버 오류로 인해 요청이 불가합니다.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      child: const Text('돌아가기'),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2196F3),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            '저장',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    ));
  }
}

class HomeView extends StatefulWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  State<HomeView> createState() => HomePage();
}

class HomePage extends State<HomeView> {

  List<RefrigeratorModel> fridgeStorage = [];

  /// 냉장고 끌어오기
  void getFridges(){
    fridgeStorage.clear();
    for(int i = 0; i < numOfFridge!; i++)
      fridgeStorage.add(RefrigeratorModel().getFridge(i));
  }

  HomePage(){
    super.initState();
    getFridges();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
        appBar: const CommonAppBar(title: 'Xnd'),
        backgroundColor: Colors.white,
        bottomNavigationBar: const MainBottomView(),
        body: PageView.builder(
            controller: PageController(),
            itemCount: fridgeStorage.length + 1,
            itemBuilder: (context, index) =>
                Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        if (index != fridgeStorage.length)
                          Text('${fridgeStorage[index].id}번 냉장고',
                            style: TextStyle(fontSize: 20))
                        else
                          Text('냉장고 추가',
                            style: TextStyle(fontSize: 20)),

                        SizedBox(height: 40),

                        if (index != fridgeStorage.length)
                          ElevatedButton(
                            onPressed: () async {
                              if (fridgeStorage[index].ingredients == null){
                                await loadFridgeIngredientsInfo(fridgeStorage[index], index);
                              }
                              getFridges();

                              if (!mounted) return;

                              setState(() {
                                pages[1] = IngredientsView(refrigerator: fridgeStorage[index]);
                              });
                              Navigator.of(context).pushNamed('/${pages[1]}');
                            },
                            child: Image.asset('assets/refrigerators/R1.png',
                                width: 180,
                                height: 180),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              shape: const CircleBorder(),
                            ),
                          )

                        else
                          ElevatedButton(
                            onPressed: () async {
                              setState(() {
                                isPlusButtonClicked = true;
                                Navigator.of(context).pushNamed('/' + pages[0].toString());
                              });
                            },
                            child: Image.asset('assets/images/plus.png',
                                width: 120,
                                height: 120),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              shape: const CircleBorder(),
                            ),
                          )
                      ]
                  ),
                ),
        )
    );
  }
}