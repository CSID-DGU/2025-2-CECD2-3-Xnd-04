# XndApp/urls.py
from django.urls import path
from XndApp.Views.RecipeViews import RecipeView, RecipeDetailView
from XndApp.Views.loginViews import KakaoLoginView
from XndApp.Views.loginViews import NaverLoginView
from XndApp.Views.fridgesViews import FridgeViews
from XndApp.Views.fridgeDetailViews import FridgeDetailView
from XndApp.Views.IngredientViews import IngredientView
from XndApp.Views.CartViews import CartListView, CartManageView, CartBulkDeleteView
from XndApp.Views.savedRecipesViews import SavedRecipesView,SavedRecipeDetailView
from XndApp.Views.NotificationViews import RegisterDeviceView, DeviceManageView, NotificationView, NotificationDetailView, IngredientNotificationView

from XndApp.Views.AccountBookViews import account_book_settings, add_expense as add_account_expense, reset_budget
from XndApp.Views.ShoppingListViews import add_shopping_list, get_shopping_list, complete_shopping, delete_shopping_items, get_daily_spending, get_monthly_spending
from XndApp.Views.ExpenseViews import get_daily_expenses, add_expense as add_daily_expense, delete_expense



urlpatterns = [
    # 로그인 및 인증
    path('api/auth/kakao-login/', KakaoLoginView.as_view(), name='kakao_login'), # 카카오 로그인
    path('api/auth/naver-login/',NaverLoginView.as_view(),name='naver_login'), # 네이버 로그인

    # 냉장고
    path('api/fridge/create/',FridgeViews.as_view(),name='create_fridge'), # 냉장고 생성
    path('api/fridge/',FridgeViews.as_view(),name='fridges'), # 냉장고 정보 조회
    path('api/fridge/<int:fridge_id>/',FridgeDetailView.as_view(),name='fridgeDetails'), # 냉장고 내부 조회(GET), 냉장고에 식재료 등록(POST)
    path('api/fridge/<int:fridge_id>/ingredients/<int:ingredient_id>/', IngredientView.as_view()), # 냉장고 속 재료 하나 선택했을 때 정보 조회(GET), 정보 수정(PATCH), 식재료 삭제(DELETE)


    # 검색
    path('api/recipes/', RecipeView.as_view(), name='recipe-list'),  # 레시피 목록 조회 ?query ?keyword ?ingredient
    path('api/recipes/<int:recipe_id>/', RecipeDetailView.as_view(), name='recipe-detail'),  # 레시피 상세 조회

    # 장바구니
    path('api/cart/', CartListView.as_view(), name='cart-list'), # 장바구니 목록 조회
    path('api/cart/add/', CartManageView.as_view(), name='cart-add'), # 장바구니에 추가
    path('api/cart/<int:cart_id>/', CartManageView.as_view(), name='cart-manage'), # 장바구니 수량 + - x (삭제)
    path('api/cart/bulk-delete/', CartBulkDeleteView.as_view(), name='cart-bulk-delete'), # 선택 삭제 (POST)
    path('api/cart/clear/', CartBulkDeleteView.as_view(), name='cart-clear'), # 전체 삭제 (DELETE)

    #즐겨찾기(레시피 저장)
    path('api/savedRecipe/', SavedRecipesView.as_view(), name='savedRecipes'),  # 저장된 레시피 목록, 즐겨찾기 추가 및 삭제(토글)
    path('api/savedRecipe/<int:id>', SavedRecipeDetailView.as_view(), name='savedRecipe-detail'), # 저장된 레시피 상세보기 및 상세보기 내에서 삭제

    # 가계부
    path('api/account-book/settings/', account_book_settings, name='account_book_settings'), # 가계부 설정 조회 및 수정
    path('api/account-book/expense/', add_account_expense, name='add_account_expense'), # 지출 추가 (가계부용)
    path('api/account-book/reset/', reset_budget, name='reset_budget'), # 예산 수동 초기화

    # 지출 내역
    path('api/expenses/', get_daily_expenses, name='get_daily_expenses'), # 특정 날짜 지출 내역 조회 (?date=YYYY-MM-DD)
    path('api/expenses/add/', add_daily_expense, name='add_daily_expense'), # 지출 내역 추가
    path('api/expenses/<int:expense_id>/', delete_expense, name='delete_expense'), # 지출 내역 삭제

    # 장보기 목록
    path('api/shopping-list/add/', add_shopping_list, name='add_shopping_list'), # 장보기 목록에 추가 (캘린더에 추가)
    path('api/shopping-list/', get_shopping_list, name='get_shopping_list'), # 특정 날짜의 장보기 목록 조회 (?date=YYYY-MM-DD)
    path('api/shopping-list/complete/', complete_shopping, name='complete_shopping'), # 장보기 완료 (가격 저장 + is_bought 업데이트 + 지출 추가)
    path('api/shopping-list/delete/', delete_shopping_items, name='delete_shopping_items'), # 장보기 항목 삭제 (완료 없이)
    path('api/shopping-list/daily-spending/', get_daily_spending, name='get_daily_spending'), # 특정 날짜의 장보기 지출 조회 (?date=YYYY-MM-DD)
    path('api/shopping-list/monthly-spending/', get_monthly_spending, name='get_monthly_spending'), # 특정 월의 날짜별 장보기 지출 조회 (?year=YYYY&month=MM)

    # 기기 관리
    path('api/devices/register/', RegisterDeviceView.as_view(), name='register_device'), # 알림 받을 기기 등록 (로그인시)
    path('api/devices/toggle/', DeviceManageView.as_view(), name='toggle_notification'), # 기기별 알림 on/off

    # 알림 관리
    path('api/notifications/', NotificationView.as_view(), name='notifications'), # 유통기한 알림 예약 생성(POST), 알림창 알림 조회(GET)
    path('api/notifications/ingredient/<int:ingredient_id>/', IngredientNotificationView.as_view(), name='ingredient_notifications'), # 식재료 유통기한 알림 예약 삭제
    path('api/notifications/<int:notification_id>/', NotificationDetailView.as_view(), name='notification_detail'), # 개별 알림 삭제 및 읽음 처리

    # CV 연동

]
