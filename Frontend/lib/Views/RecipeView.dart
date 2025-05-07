import 'package:flutter/material.dart';
import 'package:Frontend/Views/MainFrameView.dart';

class RecipeView extends StatefulWidget {
  const RecipeView({Key? key}) : super(key: key);

  @override
  State<RecipeView> createState() => RecipePage();
}

class RecipePage extends State<RecipeView> {
  String _searchQuery = '';
  TextEditingController _searchController = TextEditingController();
  late ScrollController _scrollController;

  RecipePage(){
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
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
        body: SingleChildScrollView(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  mainAppBar(name:'   Xnd'),
                  Container(
                    height: screenHeight * 0.83,
                    child: Scrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      trackVisibility: true,
                      interactive: true,
                      child: ListView(
                        controller: _scrollController,
                        children: <Widget>[
                          // 실제론 DB에서 랜덤으로 추천돌려서 레시피로 띄워줌
                          for(int i = 0; i < 10; i++)
                            Container(
                              margin: EdgeInsets.all(20),
                              height: screenHeight * 0.18,
                              decoration: BoxDecoration(
                                color: Colors.greenAccent,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: <Widget>[
                                  Container(
                                    margin: EdgeInsets.fromLTRB((screenWidth - 40) * 0.03, 0, (screenWidth - 40) * 0.04, 0),
                                    width: (screenWidth - 40) * 0.3,
                                    height: (screenWidth - 40) * 0.3,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  Container(
                                    margin: EdgeInsets.fromLTRB(0, 0, (screenWidth - 40) * 0.03, 0),
                                    width: (screenWidth - 40) * 0.6,
                                    height: (screenWidth - 40) * 0.3,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                ],
                              )
                            )
                        ]
                      )
                    ),
                  ),
                ]
            )
        ),
      bottomSheet: Container(
        height: screenHeight * 0.04,
        margin: EdgeInsets.fromLTRB(20, screenHeight * 0.01, 20, screenHeight * 0.01),
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
          style: TextStyle(color: Colors.black, fontSize: 25),
          textAlignVertical: TextAlignVertical.center,
          decoration: InputDecoration(
            hintText: (_searchQuery.isEmpty) ? '레시피 검색' : null,
            hintStyle: TextStyle(color: Colors.grey[700], fontSize: 25, fontWeight: FontWeight.bold),
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
                setState(() {
                  _searchController.clear();
                  _searchQuery = _searchController.text;
                });
              },
            ) : null,
            border: InputBorder.none,
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
      ),
    );
  }
}