import 'package:flutter/material.dart';
import 'package:Frontend/Views/HomeView.dart';
import 'package:Frontend/Views/IngredientsView.dart';
import 'package:Frontend/Views/RecipeView.dart';
import 'package:Frontend/Views/FavoritesView.dart';
import 'package:Frontend/Views/CartView.dart';
import 'package:Frontend/Views/IngredientsInfoView.dart';
import 'package:Frontend/Views/AlertView.dart';
import 'package:Frontend/Views/SettingView.dart';
import 'package:Frontend/Models/RefrigeratorModel.dart';
import 'package:Frontend/Models/RecipeModel.dart';
import 'package:Frontend/Models/IngredientModel.dart';
import 'package:Frontend/Services/loadRecipeService.dart';

Refrigerator nullProtectRefrigerator = (refrigerators.length != 0) ? refrigerators[0] : Refrigerator();

List<Widget> pages = [
  const InitialHomeView(),
  IngredientsView(refrigerator: nullProtectRefrigerator),
  const RecipeView(),
  const FavoritesView(),
  const CartView(),
  const HomeView(),
  IngredientsInfoView(ingredient: Ingredient()),
  const AlertView(),
  const SettingView(),
];

class mainAppBar extends StatelessWidget{
  String? _name;

  mainAppBar({Key? key, required name}) : super(key: key){
    this._name = name;
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        Container(
          height : screenHeight * 0.04,
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Container(
                margin: EdgeInsets.fromLTRB(10, 0, 0, 0),
                width : screenWidth * 0.25,
                child: Text(this._name.toString(),
                    style: const TextStyle(fontSize: 20, color: Colors.black, fontWeight: FontWeight.bold)),
              ),
              SizedBox(width: screenWidth * 0.5),
              Container(
                width: screenWidth * 0.1,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed('/' + pages[7].toString());
                  },
                  child: Image.asset('assets/images/alert.png', width: screenWidth * 0.05, height: screenWidth * 0.05, fit: BoxFit.cover),
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.zero,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
              Container(
                width: screenWidth * 0.1,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed('/' + pages[8].toString());
                  },
                  child: Image.asset('assets/images/setting.png', width: screenWidth * 0.05, height: screenWidth * 0.05, fit: BoxFit.cover),
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.zero,
                    backgroundColor: Colors.white,
                  ),
                ),
              )
            ],
          ),
        ),
        Container(
          color: Colors.grey[700],
          child: Divider(height: 1)
        ),
      ]
    );
  }
}

class backBar extends StatelessWidget{
  backBar({Key? key}) : super(key: key){}

  Widget build(BuildContext context){
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return Container(
      width: screenWidth,
      height: screenHeight * 0.04,
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          SizedBox(width: 10),
          IconButton(
            icon: Icon(Icons.keyboard_backspace, color: Colors.grey[700], size: 25),
            onPressed: (){
              Navigator.of(context).pop();
            },
          )
        ]
      )
    );
  }
}

AppBar basicBar(){
  return AppBar(
    backgroundColor: Colors.white,
    toolbarHeight: 0,
  );
}

class MainBottomView extends StatefulWidget {

  const MainBottomView({
    super.key,
  });

  @override
  State<MainBottomView> createState() => MainBottomBar();
}

class MainBottomBar extends State<MainBottomView> {
  // 네비게이션 바는 냉장고가 하나라도 추가되어야 활성화
  void onItemTapped(int index){
    setState(() async {
      if (refrigerators.length == 0){
        await Future.delayed(Duration.zero);
        if (index != 0) {
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
        }
        else {
          isPlusButtonClicked = false;
          Navigator.of(context).pushNamed('/' + pages[0].toString());
        }
      }
      else if (index == 0)
        Navigator.of(context).pushNamed('/' + pages[5].toString());
      // 레시피 로드
      else if (index == 2 || index == 3){
        if (recipeLoaded) {
          print('레시피가 이미 로드되었습니다.');
          Navigator.of(context).pushNamed('/' + pages[index].toString());
        }
        else {
          RecipeInfo = await getRecipeInfoFromServer();
          if (recipeLoaded)
            Navigator.of(context).pushNamed('/' + pages[index].toString());
        }
      }
      else
        Navigator.of(context).pushNamed('/' + pages[index].toString());
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return SafeArea(
      child: Container(
        height: screenHeight * 0.08,
        width: screenWidth,
        color: Colors.orangeAccent,
        child: BottomNavigationBar(
          onTap: onItemTapped,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFFFFFFFF),
          selectedItemColor: Colors.black,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'home',
            ),
            BottomNavigationBarItem(
              icon: ImageIcon(AssetImage('assets/images/menu.png')),
              label: 'refrigerator',
            ),
            BottomNavigationBarItem(
              icon: ImageIcon(AssetImage('assets/images/recipe.png')),
              label: 'recipe',
            ),
            BottomNavigationBarItem(
              icon: ImageIcon(AssetImage('assets/images/favorits.png')),
              label: 'favorits',
            ),
            BottomNavigationBarItem(
              icon: ImageIcon(AssetImage('assets/images/cart.png')),
              label: 'cart',
            ),
          ],
        )
      )
    );
  }
}