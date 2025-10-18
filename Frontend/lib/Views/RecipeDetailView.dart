import 'package:flutter/material.dart';
import 'package:Frontend/Models/RecipeModel.dart';
import 'package:Frontend/Models/IngredientModel.dart';
import 'package:Frontend/Views/MainFrameView.dart';
import 'package:Frontend/Views/LoginView.dart';
import 'package:Frontend/Services/authService.dart';

class RecipeDetailView extends StatefulWidget {
  final RecipeModel recipe;

  const RecipeDetailView({Key? key, required this.recipe}) : super(key: key);

  @override
  State<RecipeDetailView> createState() => _RecipeDetailViewState();
}

class _RecipeDetailViewState extends State<RecipeDetailView> {

  // ingredient_all 파싱
  List<IngredientModel> parseIngredients(dynamic ingredientData) {
    List<IngredientModel> ingredients = [];

    // 만약 List 형태로 들어오면
    if (ingredientData is List) {
      for (var item in ingredientData) {
        if (item is IngredientModel) {
          // IngredientModel 객체인 경우
          // amount 필드에서 "재료명: 중량" 형식일 경우 중량만 추출
          if (item.amount != null && item.amount!.contains(':')) {
            var parts = item.amount!.split(':');
            if (parts.length > 1) {
              item = IngredientModel(
                id: item.id,
                ingredientName: item.ingredientName,
                imgUrl: item.imgUrl,
                inFridge: item.inFridge,
                inCart: item.inCart,
                amount: parts[1].trim(),
              );
            }
          }
          ingredients.add(item);
        }
      }
    }

    return ingredients;
  }

  // steps 파싱
  List<String> parseSteps(dynamic stepsData) {
    List<String> stepList = [];

    // 만약 List 형태로 들어오면
    if (stepsData is List) {
      for (var step in stepsData) {
        String stepText = step.toString();
        if (stepText.isNotEmpty && stepText != 'null') {
          // 문장 단위로 분리 (마침표, 느낌표, 물음표 기준)
          // 숫자 뒤의 마침표는 제외 (예: 1.5센티, 2.5cm)
          // 마침표, 느낌표, 물음표 뒤에 공백이나 문장 끝이 오는 경우만 분리
          List<String> sentences = stepText.split(RegExp(r'(?<!\d)[.!?](?=\s|$)'));
          for (var sentence in sentences) {
            String trimmed = sentence.trim();
            if (trimmed.isNotEmpty) {
              stepList.add(trimmed);
            }
          }
        }
      }
    }

    return stepList;
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    List<IngredientModel> ingredients = parseIngredients(widget.recipe.ingredients);
    List<String> steps = parseSteps(widget.recipe.descriptions);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF2196F3),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            toolbarHeight: 80,
            automaticallyImplyLeading: false,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
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
      ),
      bottomNavigationBar: const MainBottomView(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 레시피 이미지
            Container(
              width: screenWidth,
              height: 250,
              child: widget.recipe.imgUrl != null && widget.recipe.imgUrl!.isNotEmpty
                  ? Image.network(
                      widget.recipe.imgUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
                          ),
                        );
                      },
                    )
                  : Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
                      ),
                    ),
            ),

            // 레시피 제목
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                widget.recipe.recipeName ?? '레시피',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            SizedBox(height: 12),

            // 레시피 정보 (조리시간, 인분, 난이도)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(Icons.access_time, size: 20, color: Colors.grey[700]),
                  SizedBox(width: 6),
                  Text(
                    widget.recipe.cookingTime ?? '50분',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  SizedBox(width: 16),
                  Icon(Icons.people, size: 20, color: Colors.grey[700]),
                  SizedBox(width: 6),
                  Text(
                    widget.recipe.servingSize ?? '4인분',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  SizedBox(width: 16),
                  Text(
                    '난이도',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  SizedBox(width: 6),
                  Text(
                    widget.recipe.cookingLevel ?? '쉬움',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 30),

            // Ingredients 섹션
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ingredients',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Divider(thickness: 1, color: Colors.grey[400]),
                ],
              ),
            ),

            SizedBox(height: 16),

            // 재료 리스트
            if (ingredients.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  '재료 정보가 없습니다.',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              )
            else
              ...ingredients.map((ingredient) {
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 재료명과 장바구니 버튼
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[400]!),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              ingredient.ingredientName ?? '재료',
                              style: TextStyle(fontSize: 14),
                            ),
                            SizedBox(width: 8),
                            Icon(
                              ingredient.inCart == true
                                ? Icons.shopping_cart
                                : Icons.shopping_cart_outlined,
                              size: 18,
                              color: ingredient.inCart == true
                                ? Color(0xFF2196F3)
                                : Colors.grey[700]
                            ),
                          ],
                        ),
                      ),
                      // 중량 표시
                      if (ingredient.amount != null && ingredient.amount!.isNotEmpty)
                        Text(
                          ingredient.amount!,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),

            SizedBox(height: 30),

            // Instructions 섹션
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Instructions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Divider(thickness: 1, color: Colors.grey[400]),
                ],
              ),
            ),

            SizedBox(height: 16),

            // 조리 순서
            if (steps.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  '조리 순서 정보가 없습니다.',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              )
            else
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int i = 0; i < steps.length; i++)
                      Padding(
                        padding: EdgeInsets.only(bottom: 20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Color(0xFF2196F3),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${i + 1}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                steps[i],
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
