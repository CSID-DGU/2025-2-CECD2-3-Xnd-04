# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a full-stack recipe and refrigerator management application called "Xnd" consisting of:
- **Backend**: Django REST API with JWT authentication, MySQL database, and Celery for task queue
- **Frontend**: Flutter mobile application with Kakao OAuth integration

## Development Commands

### Backend (Django)
```bash
# Navigate to backend directory
cd Backend

# Install Python dependencies
pip install -r requirements.txt

# Run database migrations
python manage.py makemigrations
python manage.py migrate

# Start development server (default: http://localhost:8000)
python manage.py runserver

# Start Celery worker (for background tasks)
celery -A Xnd worker --loglevel=info

# Start Celery beat (for scheduled tasks)
celery -A Xnd beat --loglevel=info

# Run Django tests
python manage.py test

# Import data scripts (run once for setup)
python database_import.py
python ingredient_import.py
python recipe_import.py
python tag_import.py
```

### Frontend (Flutter)
```bash
# Navigate to frontend directory
cd Frontend

# Install Flutter dependencies
flutter pub get

# Run the app (development mode)
flutter run

# Run tests
flutter test

# Build for production
flutter build apk
```

## Architecture & Key Components

### Backend Architecture
- **Main Django App**: `Xnd/` - Contains settings, URLs, and WSGI configuration
- **API App**: `XndApp/` - Contains all business logic
  - `Models/` - Database models for User, Recipe, Ingredient, Cart, Notifications, etc.
  - `Views/` - API endpoints organized by feature (Recipe, Auth, Fridge, Cart, etc.)
  - `serializers/` - DRF serializers for API responses
- **Authentication**: JWT-based with custom User model (social_id as primary key)
- **Database**: MySQL with custom models extending AbstractUser
- **Task Queue**: Celery with Redis backend for notifications and background tasks
- **Push Notifications**: Firebase Cloud Messaging (FCM) integration

### Frontend Architecture
- **Views/**: Main UI screens (MainFrameView, RecipeView, FridgeView, etc.)
- **Services/**: API service classes for backend communication
- **Models/**: Data models matching backend API responses
- **Abstracts/**: Abstract base classes for models
- **MordalViews/**: Modal dialog components

### Key API Endpoints
- Authentication: `/api/auth/kakao-login/`, `/api/auth/naver-login/`
- Recipes: `/api/recipes/` (list), `/api/recipes/<id>/` (detail)
- Refrigerator: `/api/fridge/` (CRUD operations)
- Cart: `/api/cart/` (shopping cart management)
- Saved Recipes: `/api/savedRecipe/` (favorites functionality)
- Notifications: `/api/notifications/` (expiration alerts)

## Database Configuration

The backend uses MySQL with the following setup:
- Database credentials are managed via environment variables in `.env`
- Custom User model with `social_id` as the primary identifier
- Models include: User, Recipe, Ingredient, FridgeIngredient, Cart, SavedRecipes, Notifications

## Environment Setup

### Backend Environment Variables (.env)
Required variables in `Backend/.env`:
- `SECRET_KEY` - Django secret key
- `DB_NAME`, `DB_USER`, `DB_PASSWORD`, `DB_HOST`, `DB_PORT` - MySQL credentials
- Firebase configuration (commented out but prepared for FCM)

### Frontend Environment Variables
Required variables in `Frontend/.env`:
- Kakao OAuth configuration
- API base URLs

## Development Workflow

1. **Backend Development**: Start with Django models, then create views and serializers
2. **Frontend Development**: Create corresponding service classes and models, then build UI
3. **API Testing**: Use Django admin or API browser for testing endpoints
4. **Database Changes**: Always create migrations with `makemigrations` and apply with `migrate`

## Key Dependencies

### Backend
- Django 4.2.8 with Django REST Framework
- JWT authentication via `djangorestframework-simplejwt`
- MySQL client (`mysqlclient`, `PyMySQL`)
- Celery for background tasks
- Firebase Admin SDK (prepared for FCM)

### Frontend
- Flutter SDK 3.7.2+
- HTTP client for API calls
- Kakao Flutter SDK for OAuth
- Firebase Core for push notifications
- Flutter dotenv for environment management

## Testing

- Backend: Use Django's built-in testing framework
- Frontend: Use Flutter's testing framework with `flutter test`
- API testing can be done through Django's browsable API interface

## Common Development Patterns

- **API Responses**: Consistent JSON structure with proper HTTP status codes
- **Error Handling**: Centralized error handling in both frontend and backend
- **Authentication Flow**: JWT tokens stored securely and included in API headers
- **State Management**: Flutter services handle API communication and data caching
- **Background Tasks**: Use Celery for email notifications and scheduled tasks

My name is Mhj