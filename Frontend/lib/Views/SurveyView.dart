import 'package:flutter/material.dart';
import 'package:Frontend/Widgets/CommonAppBar.dart';

class SurveyView extends StatefulWidget {
  const SurveyView({Key? key}) : super(key: key);

  @override
  State<SurveyView> createState() => _SurveyViewState();
}

class _SurveyViewState extends State<SurveyView> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // 설문 답변 저장
  final Map<String, dynamic> _answers = {
    'ingredients': <String>[],
    'favoriteRecipe': '',
    'servingSize': '',
    'cookingFrequency': '',
    'dietaryRestrictions': <String>[],
    'skillLevel': '',
  };

  final List<Map<String, dynamic>> _questions = [
    {
      'question': '주로 사용하는 식재료는 무엇인가요?',
      'type': 'multiple',
      'key': 'ingredients',
      'options': ['고기', '해산물', '채소', '과일', '곡물', '유제품', '계란', '버섯'],
    },
    {
      'question': '가장 자주하는 요리는?',
      'type': 'single',
      'key': 'favoriteRecipe',
      'options': ['한식', '중식', '일식', '양식', '분식', '베이킹', '샐러드', '기타'],
    },
    {
      'question': '주로 몇인분을 요리하나요?',
      'type': 'single',
      'key': 'servingSize',
      'options': ['1인분', '2인분', '3-4인분', '5인분 이상'],
    },
    {
      'question': '주로 요리를 얼마나 자주 하시나요?',
      'type': 'single',
      'key': 'cookingFrequency',
      'options': ['매일', '주 3-4회', '주 1-2회', '월 1-2회', '거의 안함'],
    },
    {
      'question': '특별히 피하는 음식이 있나요?',
      'type': 'multiple',
      'key': 'dietaryRestrictions',
      'options': ['없음', '매운 음식', '생선', '유제품', '글루텐', '견과류', '채식주의'],
    },
    {
      'question': '요리 실력은 어느 정도인가요?',
      'type': 'single',
      'key': 'skillLevel',
      'options': ['초보', '중급', '고급', '전문가'],
    },
  ];

  void _nextPage() {
    if (_currentPage < _questions.length - 1) {
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _submitSurvey();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _submitSurvey() {
    // TODO: 서버에 설문 결과 전송
    print('설문 결과: $_answers');

    // 설문 완료 후 이전 화면으로 돌아가기
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('설문이 완료되었습니다!'),
        duration: Duration(seconds: 2),
      ),
    );

    Future.delayed(Duration(seconds: 2), () {
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(title: 'Xnd'),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // 타이틀
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Text(
              '사전 설문조사',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ),
          // 진행 상황 표시
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '질문 ${_currentPage + 1} / ${_questions.length}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${(((_currentPage + 1) / _questions.length) * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (_currentPage + 1) / _questions.length,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  minHeight: 6,
                ),
              ],
            ),
          ),

          // 질문 페이지
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: _questions.length,
              itemBuilder: (context, index) {
                return _buildQuestionPage(_questions[index]);
              },
            ),
          ),

          // 하단 버튼
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              children: [
                if (_currentPage > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousPage,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.blue),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        '이전',
                        style: TextStyle(fontSize: 16, color: Colors.blue),
                      ),
                    ),
                  ),
                if (_currentPage > 0) SizedBox(width: 12),
                Expanded(
                  flex: _currentPage > 0 ? 1 : 1,
                  child: ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      _currentPage < _questions.length - 1 ? '다음' : '완료',
                      style: TextStyle(fontSize: 16, color: Colors.white),
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

  Widget _buildQuestionPage(Map<String, dynamic> question) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20),
          Text(
            question['question'],
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 12),
          Text(
            question['type'] == 'multiple' ? '여러 개 선택 가능' : '하나만 선택',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 32),
          _buildAnswerOptions(question),
        ],
      ),
    );
  }

  Widget _buildAnswerOptions(Map<String, dynamic> question) {
    String type = question['type'];
    String key = question['key'];
    List<String> options = question['options'];

    if (type == 'multiple') {
      return Column(
        children: options.map((option) {
          bool isSelected = (_answers[key] as List).contains(option);
          return Container(
            margin: EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    (_answers[key] as List).remove(option);
                  } else {
                    (_answers[key] as List).add(option);
                  }
                });
              },
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue[50] : Colors.white,
                  border: Border.all(
                    color: isSelected ? Colors.blue : Colors.grey[300]!,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                      color: isSelected ? Colors.blue : Colors.grey[400],
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        option,
                        style: TextStyle(
                          fontSize: 16,
                          color: isSelected ? Colors.blue[900] : Colors.grey[800],
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      );
    } else {
      return Column(
        children: options.map((option) {
          bool isSelected = _answers[key] == option;
          return Container(
            margin: EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () {
                setState(() {
                  _answers[key] = option;
                });
              },
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue[50] : Colors.white,
                  border: Border.all(
                    color: isSelected ? Colors.blue : Colors.grey[300]!,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                      color: isSelected ? Colors.blue : Colors.grey[400],
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        option,
                        style: TextStyle(
                          fontSize: 16,
                          color: isSelected ? Colors.blue[900] : Colors.grey[800],
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
