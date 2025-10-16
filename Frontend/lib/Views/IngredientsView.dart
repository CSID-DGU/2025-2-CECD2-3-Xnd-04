import 'package:Frontend/Models/RecipeModel.dart';
import 'package:flutter/material.dart';
import 'package:Frontend/Models/RefrigeratorModel.dart';
import 'package:Frontend/Views/MainFrameView.dart';
import 'package:Frontend/Services/authService.dart';
import 'package:Frontend/Views/LoginView.dart';

import '../Models/IngredientModel.dart';
import '../Services/loadDetailRecipeService.dart';
import 'IngredientsInfoView.dart';

class IngredientsView extends StatefulWidget {
  final RefrigeratorModel refrigerator;
  const IngredientsView({Key? key, required this.refrigerator}) : super(key: key);

  @override
  State<IngredientsView> createState() => IngredientsPage(refrigerator: refrigerator);
}

class IngredientsPage extends State<IngredientsView> with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late TabController _tabController;
  final RefrigeratorModel refrigerator;

  IngredientsPage({required this.refrigerator});

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  int getDueDate(FridgeIngredientModel ingredient){
    DateTime now = DateTime.now();
    DateTime dueDateParsed = DateTime.parse(ingredient.storable_due!.substring(0, 10));
    return dueDateParsed.difference(now).inDays + 1;
  }

  Color getDueDateColor(int dueDate) {
    if (dueDate <= 0) return Colors.black;
    if (dueDate == 1) return Colors.red;
    if (dueDate == 2) return Colors.orange;
    return Colors.green;
  }

  String getDueDateLabel(int dueDate) {
    if (dueDate < 0) return 'D+${dueDate.abs()}';
    return 'D-$dueDate';
  }

  // 각 층의 식재료 리스트를 가져오는 함수
  List<FridgeIngredientModel> getIngredientsForFloor(int floor) {
    if (refrigerator.ingredients == null) return [];
    return refrigerator.ingredients!.where((ingredient) =>
      ingredient.layer == floor
    ).toList();
  }

  // 모든 식재료 가져오기 (외부/냉동실용)
  List<FridgeIngredientModel> getAllIngredients() {
    if (refrigerator.ingredients == null) return [];
    return refrigerator.ingredients!;
  }

  @override
  Widget build(BuildContext context) {
    // 층별 식재료 아이템 위젯 생성
    Widget buildIngredientItem(FridgeIngredientModel ingredient) {
      int dueDate = getDueDate(ingredient);
      Color borderColor = getDueDateColor(dueDate);
      String dueDateLabel = getDueDateLabel(dueDate);

      return Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor, width: 3)
              ),
              child: FilledButton(
                onPressed: () async {
                  List<RecipeDetailModel>? recipedetails =
                      await getRecipeDetailInfoFromServer(ingredient);
                  if (!context.mounted) return;
                  pages[7] = FridgeIngredientsInfoView(
                      recipedetails: recipedetails!,
                      ingredient: ingredient
                  );
                  Navigator.of(context).pushNamed('/${pages[7]}');
                },
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)
                  ),
                  padding: EdgeInsets.zero,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(ingredient.imgUrl!, fit: BoxFit.cover),
                )
              )
            ),
          ),
          SizedBox(height: 4),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: borderColor,
              borderRadius: BorderRadius.circular(10)
            ),
            child: Text(
              dueDateLabel,
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold
              ),
            ),
          ),
        ],
      );
    }

    // 냉장실 층별 섹션 위젯
    Widget buildFloorSection(int floor) {
      List<FridgeIngredientModel> ingredients = getIngredientsForFloor(floor);
      int ingredientCount = ingredients.length;
      List<FridgeIngredientModel> previewItems = ingredients.take(4).toList();
      bool hasMore = ingredients.length > 4;

      return Container(
        margin: EdgeInsets.symmetric(vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                '$floor층($ingredientCount)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              height: 140,
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: ingredientCount == 0
                      ? Center(
                          child: Text(
                            '식재료가 없습니다',
                            style: TextStyle(color: Colors.grey[600], fontSize: 14),
                          ),
                        )
                      : GridView.builder(
                          physics: NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 0.75,
                          ),
                          itemCount: previewItems.length,
                          itemBuilder: (context, index) => buildIngredientItem(previewItems[index]),
                        ),
                  ),
                  if (hasMore)
                    Container(
                      width: 80,
                      margin: EdgeInsets.only(left: 10),
                      child: ElevatedButton(
                        onPressed: () {
                          // 더 보기 기능 (현재는 비어있음)
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[400],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)
                          ),
                          padding: EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: Text(
                          '더 보기',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // 외부/냉동실 섹션 위젯 (층 구분 없이 전체 나열)
    Widget buildAllIngredientsSection(String title) {
      List<FridgeIngredientModel> ingredients = getAllIngredients();
      int ingredientCount = ingredients.length;

      return Container(
        margin: EdgeInsets.symmetric(vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                '$title($ingredientCount)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: ingredientCount == 0
                ? Container(
                    height: 140,
                    child: Center(
                      child: Text(
                        '식재료가 없습니다',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ),
                  )
                : GridView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: ingredients.length,
                    itemBuilder: (context, index) => buildIngredientItem(ingredients[index]),
                  ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Color(0xFF2196F3),
      bottomNavigationBar: const MainBottomView(),
      body: Column(
        children: [
          // 커스텀 AppBar
          Container(
            height: 80,
            decoration: const BoxDecoration(
              color: Color(0xFF2196F3),
            ),
            child: AppBar(
              backgroundColor: Colors.transparent,
              toolbarHeight: 80,
              automaticallyImplyLeading: false,
              elevation: 0,
              title: const Text(
                'Xnd',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w400,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                  onPressed: () {
                    Navigator.of(context).pushNamed('/${pages[8]}');
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined, color: Colors.white),
                  onPressed: () {
                    Navigator.of(context).pushNamed('/${pages[9]}');
                  },
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onSelected: (String value) async {
                    if (value == 'logout') {
                      bool? confirmLogout = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('로그아웃'),
                          content: const Text('로그아웃 하시겠습니까?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('취소'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('로그아웃'),
                            ),
                          ],
                        ),
                      );

                      if (confirmLogout == true && context.mounted) {
                        await clearTokens();
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (context) => const LoginView()),
                          (route) => false,
                        );
                      }
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    return [
                      const PopupMenuItem<String>(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(Icons.logout, color: Colors.red),
                            SizedBox(width: 8),
                            Text('로그아웃', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ];
                  },
                ),
              ],
            ),
          ),
          // 탭 바
          Container(
            color: Color(0xFF2196F3),
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              unselectedLabelStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.normal),
              tabs: [
                Tab(text: '냉장실'),
                Tab(text: '외부'),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.ac_unit, size: 18),
                      SizedBox(width: 4),
                    
                  ],
                  ),
                ),
              ],
            ),
          ),
          // 탭 뷰
          Expanded(
            child: Container(
              color: Colors.white,
              child: TabBarView(
                controller: _tabController,
                children: [
                  // 냉장실 탭 - 층별로 구분
                  ListView(
                    controller: _scrollController,
                    children: [
                      for (int floor = refrigerator.level!; floor > 0; floor--)
                        buildFloorSection(floor),
                    ],
                  ),
                  // 외부 탭 - 층 구분 없이 전체 나열
                  ListView(
                    controller: _scrollController,
                    children: [
                      buildAllIngredientsSection('외부 식재료'),
                    ],
                  ),
                  // 냉동실 탭 - 층 구분 없이 전체 나열
                  ListView(
                    controller: _scrollController,
                    children: [
                      buildAllIngredientsSection('냉동실'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
