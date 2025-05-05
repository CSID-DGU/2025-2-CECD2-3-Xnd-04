import 'package:flutter/material.dart';
import 'package:Frontend/Abstracts/kakaoLogin.dart';
import 'package:Frontend/Models/LoginModel.dart';
import 'package:Frontend/Views/MainFrameView.dart';

class RecipeView extends StatefulWidget {
  const RecipeView({Key? key}) : super(key: key);

  @override
  State<RecipeView> createState() => RecipePage();
}

class RecipePage extends State<RecipeView> {
  final loginViewModel = LoginModel(KakaoLogin());
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      // 냉장고 선택 페이지 UI
        appBar: basicBar(),
        backgroundColor: Colors.white,
        bottomNavigationBar: const MainBottomView(),
        body: Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  mainAppBar(name:'   Xnd'),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        hintText: (_searchQuery.isEmpty) ? '레시피를 입력하세요' : null,
                        hintStyle: TextStyle(color: Colors.grey[700]),
                        prefixIcon: IconButton(
                          icon: Icon(Icons.search, color: Colors.grey[700]),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              // 레시피 뷰에서 어디로 쏠건지...
                            });
                          },
                        ),
                        suffixIcon: (_searchController.text.isNotEmpty)
                            ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.red),
                          onPressed: () {
                            _searchController.clear();
                          },
                        ) : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                  ),

                ]
            )
        )
    );
  }
}