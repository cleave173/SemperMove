# SemperMove

[English](#english) | [Русский](#russian)

---

## English

### What is this?

SemperMove is a fitness tracking app where you can compete with friends. Track your daily activities like steps, push-ups, squats, planks, and water intake. Challenge other users to duels and see who's better at specific exercises.

### Tech Stack

**Backend:**
- Spring Boot 3.5.6
- PostgreSQL
- JWT authentication
- Java 17

**Frontend:**
- Flutter 3.9+
- Provider for state management
- FL Chart for statistics

### Quick Start

**Backend:**
```bash
# Create database
psql -U postgres
CREATE DATABASE sempermove;
\q

# Run server
cd backend
./mvnw spring-boot:run
```

Server runs on `http://localhost:8080`

**Frontend:**
```bash
cd frontend
flutter pub get
flutter run
```

Make sure to set correct API URL in `lib/services/api_service.dart`:
- Android emulator: `http://10.0.2.2:8080/api`
- iOS simulator: `http://localhost:8080/api`
- Real device: `http://YOUR_IP:8080/api`

### Features

- User registration and login with JWT
- Track 5 types of activities (steps, push-ups, squats, plank, water)
- View statistics with charts
- Create duels with other users
- Level system and achievements
- History tracking

### Project Structure

```
backend/
  - controllers/    # API endpoints
  - models/        # User, Duel, ProgressHistory
  - services/      # Business logic
  - security/      # JWT authentication
  
frontend/
  - screens/       # App screens
  - models/        # Data models
  - services/      # API calls
```

### API Endpoints

Authentication:
- POST `/api/users/register`
- POST `/api/users/login`

Progress:
- GET `/api/progress`
- POST `/api/progress/update`

Duels:
- POST `/api/duels/start`
- GET `/api/duels/active`
- GET `/api/duels/history`
- POST `/api/duels/{id}/update-scores`
- POST `/api/duels/{id}/finish`

History:
- GET `/api/history`
- POST `/api/history/add`

### Database Setup

You need PostgreSQL running. Update credentials in `backend/src/main/resources/application.properties`:

```properties
spring.datasource.url=jdbc:postgresql://localhost:5432/sempermove
spring.datasource.username=your_username
spring.datasource.password=your_password
jwt.secret=your_secret_key_here
```

### Security

- Passwords are encrypted with BCrypt
- JWT tokens for authentication (valid 24 hours)
- Tokens stored securely in Shared Preferences on mobile

### Known Issues

If you get "Connection refused" on Android emulator, make sure you're using `10.0.2.2` instead of `localhost`.

---

## Russian

### Что это?

SemperMove - это приложение для отслеживания фитнес-активности с возможностью соревноваться с друзьями. Записывайте шаги, отжимания, приседания, планку и потребление воды. Вызывайте других пользователей на дуэли и соревнуйтесь.

### Технологии

**Бэкенд:**
- Spring Boot 3.5.6
- PostgreSQL
- JWT аутентификация
- Java 17

**Фронтенд:**
- Flutter 3.9+
- Provider для управления состоянием
- FL Chart для графиков

### Быстрый запуск

**Бэкенд:**
```bash
# Создать базу данных
psql -U postgres
CREATE DATABASE sempermove;
\q

# Запустить сервер
cd backend
./mvnw spring-boot:run
```

Сервер работает на `http://localhost:8080`

**Фронтенд:**
```bash
cd frontend
flutter pub get
flutter run
```

Укажите правильный API URL в `lib/services/api_service.dart`:
- Android эмулятор: `http://10.0.2.2:8080/api`
- iOS симулятор: `http://localhost:8080/api`
- Реальное устройство: `http://YOUR_IP:8080/api`

### Функции

- Регистрация и вход с JWT
- Отслеживание 5 видов активности (шаги, отжимания, приседания, планка, вода)
- Просмотр статистики с графиками
- Создание дуэлей с другими пользователями
- Система уровней и достижений
- История активности

### Структура проекта

```
backend/
  - controllers/    # API endpoints
  - models/        # User, Duel, ProgressHistory
  - services/      # Бизнес-логика
  - security/      # JWT аутентификация
  
frontend/
  - screens/       # Экраны приложения
  - models/        # Модели данных
  - services/      # API запросы
```

### API эндпоинты

Аутентификация:
- POST `/api/users/register`
- POST `/api/users/login`

Прогресс:
- GET `/api/progress`
- POST `/api/progress/update`

Дуэли:
- POST `/api/duels/start`
- GET `/api/duels/active`
- GET `/api/duels/history`
- POST `/api/duels/{id}/update-scores`
- POST `/api/duels/{id}/finish`

История:
- GET `/api/history`
- POST `/api/history/add`

### Настройка базы данных

Нужен запущенный PostgreSQL. Обновите данные в `backend/src/main/resources/application.properties`:

```properties
spring.datasource.url=jdbc:postgresql://localhost:5432/sempermove
spring.datasource.username=ваш_username
spring.datasource.password=ваш_пароль
jwt.secret=ваш_секретный_ключ
```

### Безопасность

- Пароли шифруются с BCrypt
- JWT токены для аутентификации (действуют 24 часа)
- Токены безопасно хранятся в Shared Preferences

### Известные проблемы

Если получаете "Connection refused" на Android эмуляторе, убедитесь что используете `10.0.2.2` вместо `localhost`.

---

**Version:** 1.0.0
