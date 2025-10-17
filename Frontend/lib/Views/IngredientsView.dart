import 'package:flutter/material.dart';
import 'package:Frontend/Models/RefrigeratorModel.dart';
import 'package:Frontend/Views/MainFrameView.dart';
import 'package:Frontend/Services/authService.dart';
import 'package:Frontend/Views/LoginView.dart';
import 'package:Frontend/Services/updateFridgeIngredientService.dart';
import 'package:Frontend/Services/loadFridgeIngredientInfoService.dart';
import 'package:Frontend/Services/loadRecipeQueryService.dart';
import 'package:Frontend/Services/deleteFridgeIngredientService.dart';
import 'package:Frontend/Models/RecipeModel.dart';

import '../Models/IngredientModel.dart';

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

  // 냉장실의 각 층 식재료 리스트를 가져오는 함수
  List<FridgeIngredientModel> getIngredientsForFloor(int floor) {
    if (refrigerator.ingredients == null) return [];
    return refrigerator.ingredients!.where((ingredient) =>
      ingredient.layer == floor && ingredient.storageLocation == 'fridge'
    ).toList();
  }

  // 외부 식재료 가져오기
  List<FridgeIngredientModel> getExternalIngredients() {
    if (refrigerator.ingredients == null) return [];
    return refrigerator.ingredients!.where((ingredient) =>
      ingredient.storageLocation == 'external'
    ).toList();
  }

  // 냉동실 식재료 가져오기
  List<FridgeIngredientModel> getFreezerIngredients() {
    if (refrigerator.ingredients == null) return [];
    return refrigerator.ingredients!.where((ingredient) =>
      ingredient.storageLocation == 'freezer'
    ).toList();
  }

  // 더 보기 다이얼로그 표시 (3x3 그리드 + 페이지 슬라이드)
  void showMoreIngredientsDialog(List<FridgeIngredientModel> ingredients, int floor) {
    // 9개씩 페이지로 나누기
    List<List<FridgeIngredientModel>> pages = [];
    for (int i = 0; i < ingredients.length; i += 9) {
      int end = (i + 9 < ingredients.length) ? i + 9 : ingredients.length;
      pages.add(ingredients.sublist(i, end));
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.7,
            child: Column(
              children: [
                // 헤더
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$floor층 (${ingredients.length})',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                // 페이지뷰로 3x3 그리드 표시
                Expanded(
                  child: PageView.builder(
                    itemCount: pages.length,
                    itemBuilder: (context, pageIndex) {
                      return Padding(
                        padding: EdgeInsets.all(16),
                        child: GridView.builder(
                          physics: NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.8,
                          ),
                          itemCount: pages[pageIndex].length,
                          itemBuilder: (context, index) {
                            return buildIngredientItem(pages[pageIndex][index]);
                          },
                        ),
                      );
                    },
                  ),
                ),
                // 페이지 인디케이터 (페이지가 2개 이상일 때만 표시)
                if (pages.length > 1)
                  Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        pages.length,
                        (index) => Container(
                          margin: EdgeInsets.symmetric(horizontal: 4),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

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
              onPressed: () {
                showIngredientDialog(ingredient);
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
                child: SizedBox.expand(
                  child: ingredient.imgUrl != null && ingredient.imgUrl!.isNotEmpty
                    ? Image.network(
                        ingredient.imgUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: Icon(Icons.image_not_supported, color: Colors.grey[600], size: 40),
                      ),
                ),
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

  // 식재료 정보 다이얼로그 표시
  void showIngredientDialog(FridgeIngredientModel initialIngredient) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            // 항상 최신 데이터를 가져오기 위해 refrigerator의 ingredients에서 찾기
            FridgeIngredientModel ingredient = refrigerator.ingredients?.firstWhere(
              (ing) => ing.id == initialIngredient.id,
              orElse: () => initialIngredient,
            ) ?? initialIngredient;

            int dueDate = getDueDate(ingredient);
            Color borderColor = getDueDateColor(dueDate);
            String dueDateLabel = getDueDateLabel(dueDate);

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.85,
                child: Stack(
                  children: [
                    Container(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 식재료 이미지 + D-day 라벨
                          Stack(
                            children: [
                              Container(
                                width: 220,
                                height: 220,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.grey[300]!, width: 2),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: ingredient.imgUrl != null && ingredient.imgUrl!.isNotEmpty
                                      ? Image.network(
                                          ingredient.imgUrl!,
                                          fit: BoxFit.cover,
                                        )
                                      : Container(
                                          color: Colors.grey[300],
                                          child: Icon(Icons.image_not_supported, color: Colors.grey[600], size: 50),
                                        ),
                                ),
                              ),
                              // D-day 라벨 (우측 상단)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: borderColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    dueDateLabel,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
                          // 식재료 이름 (가운데 정렬 + 수정 버튼)
                          GestureDetector(
                            onTap: () async {
                              // 식재료명 수정 다이얼로그
                              TextEditingController nameController = TextEditingController(text: ingredient.ingredientName);
                              String? newName = await showDialog<String>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text('식재료명 수정'),
                                  content: TextField(
                                    controller: nameController,
                                    decoration: InputDecoration(hintText: '식재료명을 입력하세요'),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text('취소'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, nameController.text),
                                      child: Text('확인'),
                                    ),
                                  ],
                                ),
                              );

                              if (newName != null && newName.isNotEmpty && newName != ingredient.ingredientName) {
                                bool success = await updateFridgeIngredient(
                                  fridgeId: refrigerator.id!,
                                  ingredientId: ingredient.id!,
                                  ingredientName: newName,
                                );
                                if (success) {
                                  await loadFridgeIngredientsInfo(refrigerator, 0);
                                  dialogSetState(() {});
                                }
                              }
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  ingredient.ingredientName ?? '오렌지',
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.edit, size: 20, color: Colors.grey),
                              ],
                            ),
                          ),
                          SizedBox(height: 16),
                          // 입고 날짜
                          Row(
                            children: [
                              Icon(Icons.calendar_today, size: 22),
                              SizedBox(width: 8),
                              Text(
                                '입고날짜',
                                style: TextStyle(fontSize: 16),
                              ),
                              Spacer(),
                              Text(
                                ingredient.stored_at?.substring(0, 10) ?? '4월 8일, 2025',
                                style: TextStyle(fontSize: 16),
                              ),
                              SizedBox(width: 26), // 유통기한 수정 아이콘 공간 확보
                            ],
                          ),
                          SizedBox(height: 12),
                          // 유통기한
                          GestureDetector(
                            onTap: () async {
                              // 유통기한 날짜 선택 다이얼로그
                              DateTime? currentDate;
                              try {
                                currentDate = ingredient.storable_due != null
                                    ? DateTime.parse(ingredient.storable_due!.substring(0, 10))
                                    : DateTime.now();
                              } catch (e) {
                                currentDate = DateTime.now();
                              }

                              DateTime? pickedDate = await showDatePicker(
                                context: context,
                                initialDate: currentDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );

                              if (pickedDate != null) {
                                String formattedDate = pickedDate.toIso8601String();
                                bool success = await updateFridgeIngredient(
                                  fridgeId: refrigerator.id!,
                                  ingredientId: ingredient.id!,
                                  storableDue: formattedDate,
                                );
                                if (success) {
                                  await loadFridgeIngredientsInfo(refrigerator, 0);
                                  dialogSetState(() {});
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('유통기한이 수정되었습니다')),
                                    );
                                  }
                                }
                              }
                            },
                            child: Row(
                              children: [
                                Icon(Icons.access_time, size: 22),
                                SizedBox(width: 8),
                                Text(
                                  '유통기한',
                                  style: TextStyle(fontSize: 16),
                                ),
                                Spacer(),
                                Text(
                                  ingredient.storable_due?.substring(0, 10) ?? '4월 20일, 2025',
                                  style: TextStyle(fontSize: 16),
                                ),
                                SizedBox(width: 4),
                                Icon(Icons.edit, size: 20, color: Colors.grey),
                              ],
                            ),
                          ),
                          SizedBox(height: 16),
                          // 메모
                          GestureDetector(
                            onTap: () async {
                              // 메모 수정 다이얼로그
                              TextEditingController memoController = TextEditingController(text: ingredient.memo ?? '');
                              int maxLength = 200;

                              String? newMemo = await showDialog<String>(
                                context: context,
                                builder: (context) => StatefulBuilder(
                                  builder: (context, setState) {
                                    return AlertDialog(
                                      title: Text('메모 수정'),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          TextField(
                                            controller: memoController,
                                            maxLines: 5,
                                            maxLength: maxLength,
                                            decoration: InputDecoration(
                                              hintText: '메모를 입력하세요 (최대 ${maxLength}자)',
                                              border: OutlineInputBorder(),
                                            ),
                                            onChanged: (value) {
                                              if (value.length > maxLength) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('메모는 최대 ${maxLength}자까지 입력 가능합니다'),
                                                    duration: Duration(seconds: 1),
                                                  ),
                                                );
                                                memoController.text = value.substring(0, maxLength);
                                                memoController.selection = TextSelection.fromPosition(
                                                  TextPosition(offset: maxLength),
                                                );
                                              }
                                              setState(() {});
                                            },
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: Text('취소'),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, memoController.text),
                                          child: Text('확인'),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              );

                              if (newMemo != null) {
                                bool success = await updateFridgeIngredient(
                                  fridgeId: refrigerator.id!,
                                  ingredientId: ingredient.id!,
                                  memo: newMemo,
                                );
                                if (success) {
                                  await loadFridgeIngredientsInfo(refrigerator, 0);
                                  dialogSetState(() {});
                                }
                              }
                            },
                            child: Container(
                              width: double.infinity,
                              height: 80,
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      ingredient.memo?.isNotEmpty == true ? ingredient.memo! : '메모를 남겨주세요',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: ingredient.memo?.isNotEmpty == true ? Colors.black : Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                          // 버튼들
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    // 레시피 검색 기능 - 식재료명으로 검색
                                    String searchQuery = ingredient.ingredientName ?? '';
                                    if (searchQuery.isNotEmpty) {
                                      // 레시피 검색 실행
                                      Recipes = await getRecipeQueryInfoFromServer(query: searchQuery);
                                      // 다이얼로그 닫고 RecipeView로 이동
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                        Navigator.of(context).pushNamed('/RecipeView');
                                      }
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey[400],
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  child: Text(
                                    '레시피 검색',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    // 추가 기능
                                    Navigator.pop(context);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey[400],
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  child: Text(
                                    '추가 기능',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () async {
                              // 삭제 확인 다이얼로그
                              bool? confirmDelete = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text('식재료 삭제'),
                                  content: Text('${ingredient.ingredientName ?? '이 식재료'}를 삭제하시겠습니까?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: Text('취소'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      child: Text('삭제', style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              );

                              if (confirmDelete == true) {
                                // 삭제 API 호출
                                bool success = await deleteFridgeIngredient(
                                  fridgeId: refrigerator.id!,
                                  ingredientId: ingredient.id!,
                                );

                                if (success) {
                                  // 냉장고 데이터 새로고침
                                  await loadFridgeIngredientsInfo(refrigerator, 0);

                                  if (context.mounted) {
                                    // 다이얼로그 닫기
                                    Navigator.pop(context);
                                    // 성공 메시지
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('식재료가 삭제되었습니다')),
                                    );
                                    // 페이지 새로고침을 위해 setState 호출
                                    setState(() {});
                                  }
                                } else {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('식재료 삭제에 실패했습니다')),
                                    );
                                  }
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[400],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 14),
                              minimumSize: Size(double.infinity, 0),
                            ),
                            child: Text(
                              '식재료 삭제',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 닫기 버튼 (우측 상단)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: Icon(Icons.close, size: 30, color: Colors.black),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 냉장실 층별 섹션 위젯
    Widget buildFloorSection(int floor) {
      List<FridgeIngredientModel> ingredients = getIngredientsForFloor(floor);
      int ingredientCount = ingredients.length;
      List<FridgeIngredientModel> previewItems = ingredients.take(4).toList();
      bool hasMore = ingredients.length > 4;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            // 층 제목
            Padding(
              padding: EdgeInsets.fromLTRB(20, 15, 20, 10),
              child: Text(
                '$floor층($ingredientCount)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            // 식재료 그리드
            Container(
              height: 130,
              padding: EdgeInsets.symmetric(horizontal: 20),
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
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: previewItems.length,
                    itemBuilder: (context, index) => buildIngredientItem(previewItems[index]),
                  ),
            ),
            // 더 보기 버튼
            if (hasMore)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () {
                      showMoreIngredientsDialog(ingredients, floor);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[400],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      minimumSize: Size(70, 32),
                    ),
                    child: Text(
                      '더 보기',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ),
                ),
              ),
            // 층 구분선
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              height: 1,
              color: Colors.grey[300],
            ),
          ],
      );
    }

    // 외부/냉동실 섹션 위젯 (층 구분 없이 전체 나열)
    Widget buildAllIngredientsSection(String title, String storageType) {
      List<FridgeIngredientModel> ingredients;
      if (storageType == 'external') {
        ingredients = getExternalIngredients();
      } else {
        ingredients = getFreezerIngredients();
      }
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
                ? SizedBox(
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
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // 커스텀 AppBar + 탭바
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFF2196F3),
              ),
              child: Column(
                children: [
                  // AppBar
                  AppBar(
                    backgroundColor: Colors.transparent,
                    toolbarHeight: 56,
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
                  // 탭 바
                  Column(
                    children: [
                      TabBar(
                        controller: _tabController,
                        indicatorColor: Colors.transparent,
                        dividerColor: Colors.transparent,
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white70,
                        labelStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        unselectedLabelStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.normal),
                        tabs: [
                          Tab(text: '냉장실'),
                          Tab(text: '외부'),
                          Tab(icon: Icon(Icons.ac_unit, size: 24)),
                        ],
                      ),
                      // 하단 radius + 슬라이드 바
                      SizedBox(
                        height: 24,
                        child: Stack(
                          children: [
                            // 하얀색 배경
                            Container(
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  topRight: Radius.circular(20),
                                ),
                              ),
                            ),
                            // 슬라이드 바 (가장 상단에 위치)
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              height: 3,
                              child: AnimatedBuilder(
                                animation: _tabController.animation!,
                                builder: (context, child) {
                                  return LayoutBuilder(
                                    builder: (context, constraints) {
                                      double tabWidth = constraints.maxWidth / 3;
                                      double indicatorWidth = tabWidth * 0.8;
                                      double offset = (tabWidth - indicatorWidth) / 2;
                                      double animationValue = _tabController.animation!.value;

                                      return Stack(
                                        children: [
                                          Positioned(
                                            left: offset + (animationValue * tabWidth),
                                            width: indicatorWidth,
                                            top: 0,
                                            bottom: 0,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Color(0xFFD3D3D3),
                                                borderRadius: BorderRadius.circular(1.5),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
                        buildAllIngredientsSection('외부 식재료', 'external'),
                      ],
                    ),
                    // 냉동실 탭 - 층 구분 없이 전체 나열
                    ListView(
                      controller: _scrollController,
                      children: [
                        buildAllIngredientsSection('냉동실', 'freezer'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
