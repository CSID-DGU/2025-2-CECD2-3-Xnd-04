import 'package:flutter/material.dart';
import 'package:Frontend/Views/HomeView.dart';
import 'package:Frontend/Views/IngredientsView.dart';
import 'package:Frontend/Views/RecipeView.dart';
import 'package:Frontend/Views/FavoritesView.dart';
import 'package:Frontend/Views/CartView.dart';
import 'package:Frontend/Views/AlertView.dart';
import 'package:Frontend/Views/SettingView.dart';
import 'package:Frontend/Models/RefrigeratorModel.dart';

List<Widget> pages = [
  const InitialHomeView(),
  IngredientsView(refrigerator: Refrigerator(),),
  const RecipeView(),
  const FavoritesView(),
  const CartView(),
  const HomeView(),
  const AlertView(),
  const SettingView(),
];

class mainAppBar extends StatelessWidget{
  const mainAppBar({Key? key}) : super(key: key);
  final String teamName = '   Xnd';

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Container(
      color: Color(0xFFFFFFFF),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Text(teamName, style: const TextStyle(fontSize: 30, color: Colors.black, fontWeight: FontWeight.bold)),
          SizedBox(width: screenWidth - 250),
          FilledButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/' + pages[6].toString());
              },
              child: Image.asset('assets/images/alert.png', width: 30, height: 30, fit: BoxFit.cover),
              style: FilledButton.styleFrom(
                minimumSize: Size(40, 40),
                backgroundColor: Color(0xFFFFFFFF),
              ),
          ),
          FilledButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/' + pages[7].toString());
              },
              child: Image.asset('assets/images/setting.png', width: 30, height: 30, fit: BoxFit.cover),
              style: FilledButton.styleFrom(
                minimumSize: Size(40, 40),
                backgroundColor: Color(0xFFFFFFFF),
              ),
          ),
        ],
      ),
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

  // 관리하는 냉장고의 UI 수에 따라 화면을 새로 그림
  void onItemTapped(int index) {
    setState(() {
      if(refrigerators.length != 0 && index == 0)
        Navigator.of(context).pushNamed('/' + pages[5].toString());
      else
        Navigator.of(context).pushNamed('/' + pages[index].toString());
    });
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      onTap: this.onItemTapped,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      type: BottomNavigationBarType.fixed,
      backgroundColor: const Color(0xFFFFFFFF),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home, size: 40),
          label: 'home',
        ),
        BottomNavigationBarItem(
          icon: ImageIcon(AssetImage('assets/images/menu.png'), size: 40),
          label: 'refrigerator',
        ),
        BottomNavigationBarItem(
          icon: ImageIcon(AssetImage('assets/images/recipe.png'), size: 40),
          label: 'recipe',
        ),
        BottomNavigationBarItem(
          icon: ImageIcon(AssetImage('assets/images/favorits.png'), size: 40),
          label: 'favorits',
        ),
        BottomNavigationBarItem(
          icon: ImageIcon(AssetImage('assets/images/cart.png'), size: 40),
          label: 'cart',
        ),
      ],
    );
  }
}