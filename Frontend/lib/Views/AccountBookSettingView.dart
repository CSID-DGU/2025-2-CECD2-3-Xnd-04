import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:Frontend/Services/accountBookService.dart';

class AccountBookSettingView extends StatefulWidget {
  const AccountBookSettingView({Key? key}) : super(key: key);

  @override
  State<AccountBookSettingView> createState() => _AccountBookSettingViewState();
}

class _AccountBookSettingViewState extends State<AccountBookSettingView> {
  final TextEditingController _autoResetBudgetController = TextEditingController();
  int autoResetBudget = 100000; // 자동 갱신 예산
  int selectedResetDay = 1; // 예산 갱신일 (1일 ~ 31일)
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAccountBookSettings();
  }

  Future<void> _loadAccountBookSettings() async {
    setState(() {
      _isLoading = true;
    });

    final settings = await getAccountBookSettings();

    if (settings != null) {
      setState(() {
        // monthly_budget가 자동 갱신 예산
        autoResetBudget = settings['monthly_budget'] ?? 100000;
        _autoResetBudgetController.text = autoResetBudget.toString();

        // 갱신일
        selectedResetDay = settings['budget_reset_day'] ?? 1;

        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('설정을 불러오는데 실패했습니다')),
        );
      }
    }
  }

  @override
  void dispose() {
    _autoResetBudgetController.dispose();
    super.dispose();
  }

  String _formatCurrency(String value) {
    if (value.isEmpty) return '';

    // 숫자만 추출
    String numericValue = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (numericValue.isEmpty) return '';

    int number = int.parse(numericValue);
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},'
    );
  }

  // 날짜 선택 다이얼로그
  void _showDayPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('예산 갱신일 선택'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: 31,
              itemBuilder: (context, index) {
                int day = index + 1;
                return ListTile(
                  title: Text(
                    '매달 $day일',
                    style: TextStyle(
                      color: selectedResetDay == day ? const Color(0xFF2196F3) : Colors.black,
                      fontWeight: selectedResetDay == day ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: selectedResetDay == day
                      ? const Icon(Icons.check, color: Color(0xFF2196F3))
                      : null,
                  onTap: () {
                    setState(() {
                      selectedResetDay = day;
                    });
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 로딩 중일 때 로딩 화면 표시
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            '가계부 설정',
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '가계부 설정',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 자동 갱신 예산 설정 섹션
              const Text(
                '자동 갱신 예산 설정',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '매달 갱신일에 자동으로 추가될 예산을 설정하세요',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 20),

              // 자동 갱신 예산 입력 필드
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '자동 추가 예산',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _autoResetBudgetController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      decoration: InputDecoration(
                        hintText: '100,000',
                        suffixText: '원',
                        suffixStyle: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // 예산 갱신일 설정 섹션
              const Text(
                '예산 갱신일 설정',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '매달 예산이 자동으로 갱신되는 날짜를 설정하세요',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 20),

              // 날짜 선택 드롭다운
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '갱신일',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '매달 $selectedResetDay일',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today, color: Color(0xFF2196F3)),
                      onPressed: () {
                        _showDayPicker();
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // 안내 메시지
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 20, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '매달 $selectedResetDay일에 ${_formatCurrency(_autoResetBudgetController.text.isNotEmpty ? _autoResetBudgetController.text : "0")}원의 예산이 자동으로 추가됩니다',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // 저장 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    String autoResetValue = _autoResetBudgetController.text.replaceAll(RegExp(r'[^0-9]'), '');

                    if (autoResetValue.isEmpty) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('자동 갱신 예산을 입력해주세요'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                      return;
                    }

                    int autoResetBudgetAmount = int.parse(autoResetValue);
                    int resetDay = selectedResetDay;

                    // API 호출: 월 예산과 갱신일 업데이트
                    bool success = await updateAccountBookSettings(
                      monthlyBudget: autoResetBudgetAmount,
                      budgetResetDay: resetDay,
                    );

                    if (!mounted) return;

                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '설정 완료\n'
                            '자동 추가 예산: ${_formatCurrency(autoResetValue)}원\n'
                            '갱신일: 매달 $selectedResetDay일'
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                      Navigator.of(context).pop();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('설정 저장에 실패했습니다'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    '저장',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
