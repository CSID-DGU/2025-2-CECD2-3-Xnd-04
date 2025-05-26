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
from XndApp.Views.NotificationViews import register_device

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
    path('api/savedRecipe/add',SavedRecipesView.as_view(),name='saveRecipe'),
    path('api/savedRecipe/',SavedRecipesView.as_view(),name='savedRecipes'),
    path('api/savedRecipe/<int:id>',SavedRecipeDetailView.as_view(),name='savedRecipe-detail'),

    # 푸시 알림
    path('api/devices/register/', register_device, name='registerDevice'),  # 기기 등록
]
