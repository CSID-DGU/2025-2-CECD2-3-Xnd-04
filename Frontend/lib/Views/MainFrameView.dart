import 'package:flutter/material.dart';
import 'package:Frontend/Views/HomeView.dart';
import 'package:Frontend/Views/IngredientsView.dart';
import 'package:Frontend/Views/RecipeView.dart';
import 'package:Frontend/Views/FavoritesView.dart';
import 'package:Frontend/Views/CartView.dart';
import 'package:Frontend/Views/AlertView.dart';
import 'package:Frontend/Views/SettingView.dart';


List<Widget> pages = [
  const HomeView(),
  const IngredientsView(levelOfRefrigerator: 0,),
  const RecipeView(),
  const FavoritesView(),
  const CartView(),
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
                Navigator.push(context, MaterialPageRoute(
                  builder: (i) => pages[5],
                  )
                );
              },
              child: Image.asset('assets/images/alert.png', width: 30, height: 30, fit: BoxFit.cover),
              style: FilledButton.styleFrom(
                minimumSize: Size(40, 40),
                backgroundColor: Color(0xFFFFFFFF),
              ),
          ),
          FilledButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(
                builder: (i) => pages[6],
                  )
                );
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

  void onItemTapped(int index) {
    setState(() {
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
          label: 'refrigerator',
        ),
        BottomNavigationBarItem(
          icon: ImageIcon(AssetImage('assets/images/menu.png'), size: 40),
          label: 'menu',
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