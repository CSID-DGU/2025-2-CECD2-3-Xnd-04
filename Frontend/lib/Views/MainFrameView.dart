import 'package:flutter/material.dart';
import 'package:Frontend/Views/HomeView.dart';
import 'package:Frontend/Views/IngredientsView.dart';
import 'package:Frontend/Views/RecipeView.dart';
import 'package:Frontend/Views/FavoritesView.dart';
import 'package:Frontend/Views/CartView.dart';
import 'package:Frontend/Views/AccountBookView.dart';
import 'package:Frontend/Views/IngredientsInfoView.dart';
import 'package:Frontend/Views/AlertView.dart';
import 'package:Frontend/Views/SettingView.dart';
import 'package:Frontend/Views/SearchView.dart';
import 'package:Frontend/Models/RefrigeratorModel.dart';
import 'package:Frontend/Models/RecipeModel.dart';
import 'package:Frontend/Models/IngredientModel.dart';
import 'package:Frontend/Services/loadRecipeService.dart';
import 'package:Frontend/Services/loadFridgeIngredientInfoService.dart';

import '../Services/loadSavedRecipeService.dart';

RefrigeratorModel nullProtectRefrigerator = (Fridges.isNotEmpty) ? Fridges[0] : RefrigeratorModel();

List<Widget> pages = [
  const InitialHomeView(),
  IngredientsView(refrigerator: nullProtectRefrigerator),
  const RecipeView(),
  const FavoritesView(),
  const CartView(),
  const HomeView(),
  IngredientsInfoView(recipedetails : [RecipeDetailModel()], ingredient: IngredientModel(), inform: {}),
  FridgeIngredientsInfoView(recipedetails : [RecipeDetailModel()], ingredient: FridgeIngredientModel()),
  const AlertView(),
  const SettingView(),
  const AccountBookView(),
  const SearchView(),
];

bool recipeFirstLoading = true;
bool savedRecipeFirstLoading = true;

/// 네비게이션 처리 여부에 따라 build에서 함수를 실행시킬 지 말 지 결정
bool nav2Processed = true;
bool nav3Processed = true;

/// 현재 선택된 하단 네비게이션 인덱스 (전역)
int currentBottomNavIndex = 0;

class MainBottomView extends StatefulWidget {

  const MainBottomView({
    super.key,
  });

  @override
  State<MainBottomView> createState() => MainBottomBar();
}

class MainBottomBar extends State<MainBottomView> {
  // 네비게이션 바는 냉장고가 하나라도 추가되어야 활성화
  void onItemTapped(int index) async {
    // 냉장고가 없으면 경고 표시 (IngredientsView만)
    if (Fridges.isEmpty && index == 0){
      await Future.delayed(Duration.zero);
      showDialog(
          context: context,
          builder: (context) =>
              AlertDialog(
                title: Text('경고'),
                content: Text('+ 버튼을 눌러 냉장고를 추가해 주세요'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('확 인'),
                  ),
                ],
              )
      );
      return;
    }

    // 현재 인덱스 업데이트 (전역 변수)
    setState(() {
      currentBottomNavIndex = index;
    });

    // 0: IngredientsView
    if (index == 0){
      // 냉장고 식재료 정보 로드
      if (Fridges.isNotEmpty && Fridges[0].ingredients == null) {
        await loadFridgeIngredientsInfo(Fridges[0], 0);
      }
      if (!mounted) return;
      Navigator.of(context).pushNamed('/${pages[1]}');
    }
    // 1: SearchView (검색 페이지)
    else if (index == 1){
      Navigator.of(context).pushNamed('/' + pages[11].toString());
    }
    // 2: AccountBookView
    else if (index == 2){
      Navigator.of(context).pushNamed('/' + pages[10].toString());
    }
    // 3: CartView
    else if (index == 3){
      Navigator.of(context).pushNamed('/' + pages[4].toString());
    }
    // 4: FavoritesView
    else if (index == 4){
      if (savedRecipeFirstLoading) {
        SavedRecipes = await getSavedRecipesFromServer();
        savedRecipeFirstLoading = false;
      }
      nav3Processed = false;
      Navigator.of(context).pushNamed('/' + pages[3].toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return BottomNavigationBar(
      currentIndex: currentBottomNavIndex,
      onTap: onItemTapped,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      type: BottomNavigationBarType.fixed,
      backgroundColor: const Color(0xFFFFFFFF),
      selectedItemColor: const Color(0xFF2196F3),
      unselectedItemColor: Colors.grey,
      elevation: 8,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'ingredients',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.search),
          label: 'recipe',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: 'accountbook',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.local_mall),
          label: 'cart',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.star),
          label: 'favorites',
        ),
      ],
    );
  }
}