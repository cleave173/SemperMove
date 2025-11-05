# 📡 API Мысалдары

## 🔐 Аутентификация

### Регистрация
\`\`\`bash
curl -X POST http://localhost:8080/api/users/register \\
  -H "Content-Type: application/json" \\
  -d '{
    "email": "user@example.com",
    "username": "TestUser",
    "password": "123456"
  }'
\`\`\`

**Жауап:**
\`\`\`json
{
  "message": "User registered successfully",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "username": "TestUser",
    "dailySteps": 0,
    "pushUps": 0,
    "squats": 0,
    "plankSeconds": 0,
    "waterMl": 0
  }
}
\`\`\`

### Кіру
\`\`\`bash
curl -X POST http://localhost:8080/api/users/login \\
  -H "Content-Type: application/json" \\
  -d '{
    "email": "user@example.com",
    "password": "123456"
  }'
\`\`\`

**Жауап:**
\`\`\`json
{
  "token": "eyJhbGciOiJIUzI1NiJ9...",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "username": "TestUser",
    ...
  }
}
\`\`\`

## 📊 Прогресс

### Прогрессті алу
\`\`\`bash
curl -X GET http://localhost:8080/api/progress \\
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
\`\`\`

### Прогрессті жаңарту
\`\`\`bash
curl -X POST http://localhost:8080/api/progress/update \\
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \\
  -H "Content-Type: application/json" \\
  -d '{
    "dailySteps": 5000,
    "pushUps": 30,
    "squats": 50,
    "plankSeconds": 120,
    "waterMl": 1500
  }'
\`\`\`

## ⚔️ Дуэльдер

### Дуэль жасау
\`\`\`bash
curl -X POST http://localhost:8080/api/duels/start \\
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \\
  -H "Content-Type: application/json" \\
  -d '{
    "opponentId": 2,
    "exerciseCategory": "pushups"
  }'
\`\`\`

**Жауап:**
\`\`\`json
{
  "message": "Дуэль создана успешно",
  "duel": {
    "id": 1,
    "challenger": {
      "id": 1,
      "username": "TestUser",
      "email": "user@example.com"
    },
    "opponent": {
      "id": 2,
      "username": "Opponent",
      "email": "opponent@example.com"
    },
    "status": "IN_PROGRESS",
    "exerciseCategory": "pushups",
    "challengerScore": 0,
    "opponentScore": 0,
    ...
  }
}
\`\`\`

### Активті дуэльдер
\`\`\`bash
curl -X GET http://localhost:8080/api/duels/active \\
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
\`\`\`

### Дуэль тарихы
\`\`\`bash
curl -X GET http://localhost:8080/api/duels/history \\
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
\`\`\`

### Дуэль деталдары
\`\`\`bash
curl -X GET http://localhost:8080/api/duels/1 \\
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
\`\`\`

### Ұпайларды жаңарту
\`\`\`bash
curl -X POST http://localhost:8080/api/duels/1/update-scores \\
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \\
  -H "Content-Type: application/json" \\
  -d '{
    "challengerScore": 30,
    "opponentScore": 25
  }'
\`\`\`

### Дуэльді аяқтау
\`\`\`bash
curl -X POST http://localhost:8080/api/duels/1/finish \\
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
\`\`\`

**Жауап:**
\`\`\`json
{
  "message": "Дуэль завершена",
  "winner": "TestUser",
  "totalChallengerScore": 30,
  "totalOpponentScore": 25,
  "duel": {...}
}
\`\`\`

## 📈 Тарих

### Прогресс тарихын алу
\`\`\`bash
curl -X GET http://localhost:8080/api/history \\
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
\`\`\`

### Тарихқа қосу
\`\`\`bash
curl -X POST http://localhost:8080/api/history/add \\
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \\
  -H "Content-Type: application/json" \\
  -d '{
    "steps": 5000,
    "pushUps": 30,
    "squats": 50,
    "plankSeconds": 120,
    "waterMl": 1500
  }'
\`\`\`

## 👥 Қолданушылар

### Барлық қолданушылар
\`\`\`bash
curl -X GET http://localhost:8080/api/users/all \\
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
\`\`\`

## 🛡️ Қате жауаптары

### 400 Bad Request
\`\`\`json
{
  "error": "Email already exists"
}
\`\`\`

### 401 Unauthorized
\`\`\`json
{
  "error": "Invalid email or password"
}
\`\`\`

### 404 Not Found
\`\`\`json
{
  "error": "User not found"
}
\`\`\`

## 🧪 Postman Collection

### Import келесі JSON-ды Postman-ға:

\`\`\`json
{
  "info": {
    "name": "Semper Move API",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
  },
  "item": [
    {
      "name": "Auth",
      "item": [
        {
          "name": "Register",
          "request": {
            "method": "POST",
            "header": [{"key": "Content-Type", "value": "application/json"}],
            "body": {
              "mode": "raw",
              "raw": "{\\n  \\"email\\": \\"user@example.com\\",\\n  \\"username\\": \\"TestUser\\",\\n  \\"password\\": \\"123456\\"\\n}"
            },
            "url": {"raw": "http://localhost:8080/api/users/register"}
          }
        },
        {
          "name": "Login",
          "request": {
            "method": "POST",
            "header": [{"key": "Content-Type", "value": "application/json"}],
            "body": {
              "mode": "raw",
              "raw": "{\\n  \\"email\\": \\"user@example.com\\",\\n  \\"password\\": \\"123456\\"\\n}"
            },
            "url": {"raw": "http://localhost:8080/api/users/login"}
          }
        }
      ]
    }
  ]
}
\`\`\`

## 💡 Кеңестер

1. **Token-ді environment variable-ға сақтаңыз:**
   \`\`\`bash
   export TOKEN="eyJhbGciOiJIUzI1NiJ9..."
   curl -H "Authorization: Bearer $TOKEN" ...
   \`\`\`

2. **jq қолданып JSON форматтаңыз:**
   \`\`\`bash
   curl ... | jq '.'
   \`\`\`

3. **Response уақытын өлшеңіз:**
   \`\`\`bash
   curl -w "\\nTime: %{time_total}s\\n" ...
   \`\`\`


