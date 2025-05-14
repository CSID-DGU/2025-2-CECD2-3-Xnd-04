# XndApp/urls.py
from django.urls import path
from XndApp.Views.RecipeViews import RecipeView, RecipeDetailView

urlpatterns = [
    path('api/recipes/', RecipeView.as_view(), name='recipe-list'),
    path('api/recipes/<int:recipe_id>/', RecipeDetailView.as_view(), name='recipe-detail'),
]