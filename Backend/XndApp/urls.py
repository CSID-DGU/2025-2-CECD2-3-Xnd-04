# XndApp/urls.py
from django.urls import path
from XndApp.Views.RecipeViews import RecipeView, RecipeDetailView
from XndApp.Views.loginViews import KakaoLoginView
from XndApp.Views.loginViews import NaverLoginView
from XndApp.Views.fridgesViews import FridgeViews
from XndApp.Views.fridgeDetailViews import FridgeDetailView
from XndApp.Views.IngredientViews import IngredientView
from XndApp.Views.CartViews import CartListView, CartManageView
from XndApp.Views.savedRecipesViews import SavedRecipesView,SavedRecipeDetailView
from XndApp.Views.NotificationViews import RegisterDeviceView, DeviceManageView, NotificationView, NotificationDetailView, IngredientNotificationView
from XndApp.Views.fcmViews import fcm_test_view
#from XndApp.Views.cv_views

urlpatterns = [
    # 로그인 및 인증
    path('api/auth/kakao-login/', KakaoLoginView.as_view(), name='kakao_login'), # 카카오 로그인
    path('api/auth/naver-login/',NaverLoginView.as_view(),name='naver_login'), # 네이버 로그인

    # 냉장고
    path('api/fridge/create/',FridgeViews.as_view(),name='create_fridge'), # 냉장고 생성
    path('api/fridge/',FridgeViews.as_view(),name='fridges'), # 냉장고 정보 조회
    path('api/fridge/<int:fridge_id>/',FridgeDetailView.as_view(),name='fridgeDetails'), # 냉장고 내부 조회
    path('api/fridge/<int:fridge_id>/ingredients/<int:ingredient_id>/', IngredientView.as_view()), # 냉장고 속 재료 하나 선택했을 때 정보 조회

    # 검색
    path('api/recipes/', RecipeView.as_view(), name='recipe-list'),  # 레시피 목록 조회 ?query ?keyword ?ingredient
    path('api/recipes/<int:recipe_id>/', RecipeDetailView.as_view(), name='recipe-detail'),  # 레시피 상세 조회

    # 장바구니
    path('api/cart/', CartListView.as_view(), name='cart-list'), # 장바구니 목록 조회
    path('api/cart/add/', CartManageView.as_view(), name='cart-add'), # 장바구니에 추가
    path('api/cart/<int:cart_id>/', CartManageView.as_view(), name='cart-manage'), # 장바구니 수량 + - x (삭제)

    #즐겨찾기(레시피 저장)
    path('api/savedRecipe/', SavedRecipesView.as_view(), name='savedRecipes'),  # 저장된 레시피 목록, 즐겨찾기 추가 및 삭제(토글)
    path('api/savedRecipe/<int:id>', SavedRecipeDetailView.as_view(), name='savedRecipe-detail'), # 저장된 레시피 상세보기 및 상세보기 내에서 삭제

    # 기기 관리
    path('api/devices/register/', RegisterDeviceView.as_view(), name='register_device'), # 알림 받을 기기 등록 (로그인시)
    path('api/devices/toggle/', DeviceManageView.as_view(), name='toggle_notification'), # 기기별 알림 on/off

    # 알림 관리
    path('api/notifications/', NotificationView.as_view(), name='notifications'), # 유통기한 알림 예약 생성(POST), 알림창 알림 조회(GET)
    path('api/notifications/ingredient/<int:ingredient_id>/', IngredientNotificationView.as_view(), name='ingredient_notifications'), # 식재료 유통기한 알림 예약 삭제
    path('api/notifications/<int:notification_id>/', NotificationDetailView.as_view(), name='notification_detail'), # 개별 알림 삭제 및 읽음 처리

    # 푸시 테스트
    path('fcm-test/', fcm_test_view, name='fcm_test'), # 테스트용 웹 FCM 발급 (추후 프론트로 수정)

    # CV 연동
    path

]
