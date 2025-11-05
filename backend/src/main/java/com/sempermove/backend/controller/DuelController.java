package com.sempermove.backend.controller;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.sempermove.backend.model.Duel;
import com.sempermove.backend.model.User;
import com.sempermove.backend.repository.DuelRepository;
import com.sempermove.backend.repository.UserRepository;
import com.sempermove.backend.security.JwtUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.*;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/duels")
public class DuelController {

    @Autowired
    private DuelRepository duelRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private JwtUtil jwtUtil;

    private final ObjectMapper objectMapper = new ObjectMapper();

    // Список доступных упражнений
    private final Set<String> AVAILABLE_EXERCISES = Set.of(
        "pushups", "squats", "plank", "steps"
    );

    // ✅ УНИВЕРСАЛЬНОЕ создание дуэли (1 или несколько категорий)
    @PostMapping("/start")
    public ResponseEntity<?> startDuel(
            @RequestHeader("Authorization") String authHeader,
            @RequestBody Map<String, Object> request
    ) {
        try {
            String token = authHeader.substring(7);
            String email = jwtUtil.extractEmail(token);
            User challenger = userRepository.findByEmail(email)
                    .orElseThrow(() -> new RuntimeException("Пользователь не найден"));

            // Валидация входных данных
            if (!request.containsKey("opponentId")) {
                return ResponseEntity.badRequest().body(Map.of(
                    "error", "Необходим opponentId"
                ));
            }

            // Проверяем оба варианта: exerciseCategory и exerciseCategories
            boolean hasSingleCategory = request.containsKey("exerciseCategory");
            boolean hasMultipleCategories = request.containsKey("exerciseCategories");
            
            if (!hasSingleCategory && !hasMultipleCategories) {
                return ResponseEntity.badRequest().body(Map.of(
                    "error", "Необходим exerciseCategory (строка) или exerciseCategories (массив)"
                ));
            }

            Long opponentId;
            try {
                opponentId = Long.parseLong(request.get("opponentId").toString());
            } catch (NumberFormatException e) {
                return ResponseEntity.badRequest().body(Map.of(
                    "error", "Некорректный opponentId"
                ));
            }

            // Проверка существования оппонента
            User opponent = userRepository.findById(opponentId)
                    .orElseThrow(() -> new RuntimeException("Оппонент не найден"));

            // Проверка что пользователь не создает дуэль с самим собой
            if (challenger.getId().equals(opponentId)) {
                return ResponseEntity.badRequest().body(Map.of(
                    "error", "Нельзя создать дуэль с самим собой"
                ));
            }

            List<String> exerciseCategories;
            
            // Обрабатываем оба варианта входных данных
            if (hasSingleCategory) {
                // Одна категория
                String exerciseCategory = request.get("exerciseCategory").toString();
                exerciseCategories = List.of(exerciseCategory);
            } else {
                // Несколько категорий
                exerciseCategories = objectMapper.convertValue(
                    request.get("exerciseCategories"), 
                    new TypeReference<List<String>>() {}
                );
            }

            if (exerciseCategories == null || exerciseCategories.isEmpty()) {
                return ResponseEntity.badRequest().body(Map.of(
                    "error", "Необходимо указать хотя бы одну категорию упражнений"
                ));
            }

            // Проверка допустимости упражнений
            List<String> invalidExercises = exerciseCategories.stream()
                    .filter(category -> !AVAILABLE_EXERCISES.contains(category.toLowerCase()))
                    .collect(Collectors.toList());

            if (!invalidExercises.isEmpty()) {
                return ResponseEntity.badRequest().body(Map.of(
                    "error", "Недопустимые категории упражнений: " + invalidExercises,
                    "availableExercises", AVAILABLE_EXERCISES
                ));
            }

            // Нормализуем названия категорий
            List<String> normalizedCategories = exerciseCategories.stream()
                    .map(String::toLowerCase)
                    .collect(Collectors.toList());

            // Проверка на активную дуэль с тем же оппонентом и упражнениями
            List<Duel> existingDuels = duelRepository.findByChallengerAndStatus(challenger, "IN_PROGRESS");
            boolean hasActiveDuel = existingDuels.stream()
                    .anyMatch(duel -> {
                        if (!duel.getOpponent().getId().equals(opponentId)) {
                            return false;
                        }
                        
                        // Для дуэлей с несколькими категориями
                        if (duel.isMultipleCategories()) {
                            return new HashSet<>(duel.getExercisesMap().keySet()).containsAll(normalizedCategories);
                        } 
                        // Для дуэлей с одной категорией
                        else if (duel.isSingleCategory()) {
                            return normalizedCategories.size() == 1 && 
                                   normalizedCategories.get(0).equals(duel.getExerciseCategory());
                        }
                        return false;
                    });
            
            if (hasActiveDuel) {
                return ResponseEntity.badRequest().body(Map.of(
                    "error", "У вас уже есть активная дуэль с этим пользователем по данным упражнениям"
                ));
            }

            // Создание дуэли
            Duel duel = new Duel();
            duel.setChallenger(challenger);
            duel.setOpponent(opponent);
            duel.setStatus("IN_PROGRESS");
            
            // Если одна категория - используем старые поля для совместимости
            if (normalizedCategories.size() == 1) {
                duel.setExerciseCategory(normalizedCategories.get(0));
                duel.setChallengerScore(0);
                duel.setOpponentScore(0);
            } else {
                // Если несколько категорий - используем exercises map
                Map<String, String> exercisesMap = new HashMap<>();
                for (String category : normalizedCategories) {
                    exercisesMap.put(category, "0:0"); // формат: challenger:opponent
                }
                duel.setExercisesMap(exercisesMap);
            }

            Duel savedDuel = duelRepository.save(duel);

            return ResponseEntity.ok(Map.of(
                "message", "Дуэль создана успешно",
                "duel", createDuelResponse(savedDuel)
            ));

        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.badRequest().body(Map.of(
                "error", "Ошибка при создании дуэли: " + e.getMessage()
            ));
        }
    }

    // ✅ УНИВЕРСАЛЬНОЕ обновление очков (1 или несколько категорий)
    @PostMapping("/{duelId}/update-scores")
    public ResponseEntity<?> updateScores(
            @PathVariable Long duelId,
            @RequestBody Map<String, Object> request
    ) {
        try {
            Duel duel = duelRepository.findById(duelId)
                    .orElseThrow(() -> new RuntimeException("Дуэль не найдена"));

            if (!"IN_PROGRESS".equals(duel.getStatus())) {
                return ResponseEntity.badRequest().body(Map.of(
                    "error", "Нельзя обновлять очки завершенной дуэли"
                ));
            }

            // Определяем тип дуэли
            if (duel.isSingleCategory()) {
                // Обновление для одной категории
                if (!request.containsKey("challengerScore") || !request.containsKey("opponentScore")) {
                    return ResponseEntity.badRequest().body(Map.of(
                        "error", "Для дуэли с одной категорией необходимы challengerScore и opponentScore"
                    ));
                }

                int challengerScore = Integer.parseInt(request.get("challengerScore").toString());
                int opponentScore = Integer.parseInt(request.get("opponentScore").toString());

                if (challengerScore < 0 || opponentScore < 0) {
                    return ResponseEntity.badRequest().body(Map.of(
                        "error", "Очки не могут быть отрицательными"
                    ));
                }

                duel.setChallengerScore(challengerScore);
                duel.setOpponentScore(opponentScore);

            } else if (duel.isMultipleCategories()) {
                // Обновление для нескольких категорий
                if (!request.containsKey("scores")) {
                    return ResponseEntity.badRequest().body(Map.of(
                        "error", "Для дуэли с несколькими категориями необходим объект scores"
                    ));
                }

                @SuppressWarnings("unchecked")
                Map<String, Map<String, Integer>> scores = (Map<String, Map<String, Integer>>) request.get("scores");

                Map<String, String> exercises = duel.getExercisesMap();
                
                for (Map.Entry<String, Map<String, Integer>> entry : scores.entrySet()) {
                    String category = entry.getKey().toLowerCase();
                    Map<String, Integer> categoryScores = entry.getValue();
                    
                    if (exercises.containsKey(category)) {
                        int challengerScore = categoryScores.getOrDefault("challenger", 0);
                        int opponentScore = categoryScores.getOrDefault("opponent", 0);
                        
                        if (challengerScore < 0 || opponentScore < 0) {
                            return ResponseEntity.badRequest().body(Map.of(
                                "error", "Очки не могут быть отрицательными для категории: " + category
                            ));
                        }
                        
                        exercises.put(category, challengerScore + ":" + opponentScore);
                    } else {
                        return ResponseEntity.badRequest().body(Map.of(
                            "error", "Категория не найдена в дуэли: " + category,
                            "availableCategories", exercises.keySet()
                        ));
                    }
                }

                duel.setExercisesMap(exercises);
            } else {
                return ResponseEntity.badRequest().body(Map.of(
                    "error", "Некорректный формат дуэли"
                ));
            }

            Duel updatedDuel = duelRepository.save(duel);

            return ResponseEntity.ok(Map.of(
                "message", "Очки обновлены успешно",
                "duel", createDuelResponse(updatedDuel)
            ));

        } catch (NumberFormatException e) {
            return ResponseEntity.badRequest().body(Map.of(
                "error", "Некорректный формат очков"
            ));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of(
                "error", "Ошибка при обновлении очков: " + e.getMessage()
            ));
        }
    }

    // ✅ Завершение дуэли (работает для обоих типов)
    @PostMapping("/{duelId}/finish")
    public ResponseEntity<?> finishDuel(@PathVariable Long duelId) {
        try {
            Duel duel = duelRepository.findById(duelId)
                    .orElseThrow(() -> new RuntimeException("Дуэль не найдена"));

            if ("FINISHED".equals(duel.getStatus())) {
                return ResponseEntity.badRequest().body(Map.of(
                    "error", "Дуэль уже завершена"
                ));
            }

            int totalChallengerScore = duel.getTotalChallengerScore();
            int totalOpponentScore = duel.getTotalOpponentScore();

            // Определение победителя
            String winner;
            if (totalChallengerScore > totalOpponentScore) {
                winner = duel.getChallenger().getUsername();
            } else if (totalOpponentScore > totalChallengerScore) {
                winner = duel.getOpponent().getUsername();
            } else {
                winner = "Draw";
            }

            duel.setWinner(winner);
            duel.setStatus("FINISHED");
            Duel finishedDuel = duelRepository.save(duel);

            return ResponseEntity.ok(Map.of(
                "message", "Дуэль завершена",
                "winner", winner,
                "totalChallengerScore", totalChallengerScore,
                "totalOpponentScore", totalOpponentScore,
                "duel", createDuelResponse(finishedDuel)
            ));

        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of(
                "error", "Ошибка при завершении дуэли: " + e.getMessage()
            ));
        }
    }

    // ✅ История дуэлей текущего пользователя (работает для обоих типов)
    @GetMapping("/history")
    public ResponseEntity<?> getDuelHistory(@RequestHeader("Authorization") String authHeader) {
        try {
            String token = authHeader.substring(7);
            String email = jwtUtil.extractEmail(token);
            User user = userRepository.findByEmail(email)
                    .orElseThrow(() -> new RuntimeException("Пользователь не найден"));

            List<Duel> duels = duelRepository.findByChallengerOrOpponent(user, user);
            List<Map<String, Object>> duelHistory = duels.stream()
                    .sorted((d1, d2) -> {
                        if (d1.getCreatedAt() != null && d2.getCreatedAt() != null) {
                            return d2.getCreatedAt().compareTo(d1.getCreatedAt());
                        }
                        return d2.getId().compareTo(d1.getId());
                    })
                    .map(this::createDuelResponse)
                    .collect(Collectors.toList());

            return ResponseEntity.ok(Map.of(
                "duels", duelHistory,
                "total", duelHistory.size()
            ));

        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of(
                "error", "Ошибка при получении истории: " + e.getMessage()
            ));
        }
    }

    // ✅ Активные дуэли пользователя
    @GetMapping("/active")
    public ResponseEntity<?> getActiveDuels(@RequestHeader("Authorization") String authHeader) {
        try {
            String token = authHeader.substring(7);
            String email = jwtUtil.extractEmail(token);
            User user = userRepository.findByEmail(email)
                    .orElseThrow(() -> new RuntimeException("Пользователь не найден"));

            List<Duel> activeDuels = duelRepository.findActiveDuelsByUser(user);
            List<Map<String, Object>> duelList = activeDuels.stream()
                    .map(this::createDuelResponse)
                    .collect(Collectors.toList());

            return ResponseEntity.ok(Map.of(
                "activeDuels", duelList,
                "count", duelList.size()
            ));

        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of(
                "error", "Ошибка при получении активных дуэлей: " + e.getMessage()
            ));
        }
    }

    // ✅ Получение информации о конкретной дуэли
    @GetMapping("/{duelId}")
    public ResponseEntity<?> getDuel(@PathVariable Long duelId) {
        try {
            Duel duel = duelRepository.findById(duelId)
                    .orElseThrow(() -> new RuntimeException("Дуэль не найдена"));

            return ResponseEntity.ok(createDuelResponse(duel));

        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of(
                "error", "Ошибка при получении дуэли: " + e.getMessage()
            ));
        }
    }

    // ✅ Получение доступных упражнений
    @GetMapping("/exercises")
    public ResponseEntity<?> getAvailableExercises() {
        return ResponseEntity.ok(Map.of(
            "availableExercises", new ArrayList<>(AVAILABLE_EXERCISES)
        ));
    }

    // Вспомогательный метод для создания ответа с дуэлью (универсальный)
    private Map<String, Object> createDuelResponse(Duel duel) {
        Map<String, Object> response = new HashMap<>();
        response.put("id", duel.getId());
        response.put("challenger", Map.of(
            "id", duel.getChallenger().getId(),
            "username", duel.getChallenger().getUsername(),
            "email", duel.getChallenger().getEmail()
        ));
        response.put("opponent", Map.of(
            "id", duel.getOpponent().getId(),
            "username", duel.getOpponent().getUsername(),
            "email", duel.getOpponent().getEmail()
        ));
        response.put("status", duel.getStatus());
        response.put("winner", duel.getWinner());
        response.put("createdAt", duel.getCreatedAt());
        response.put("updatedAt", duel.getUpdatedAt());

        // Определяем тип дуэли и добавляем соответствующую информацию
        if (duel.isMultipleCategories()) {
            // Дуэль с несколькими категориями
            response.put("type", "MULTIPLE_CATEGORIES");
            response.put("exerciseCategories", new ArrayList<>(duel.getExercisesMap().keySet()));
            response.put("exercises", formatExercisesResponse(duel.getExercisesMap()));
            response.put("totalScores", calculateTotalScores(duel.getExercisesMap()));
        } else {
            // Дуэль с одной категорией
            response.put("type", "SINGLE_CATEGORY");
            response.put("exerciseCategory", duel.getExerciseCategory());
            response.put("challengerScore", duel.getChallengerScore());
            response.put("opponentScore", duel.getOpponentScore());
        }
        
        return response;
    }

    // Вспомогательный метод для форматирования упражнений
    private Map<String, Map<String, Integer>> formatExercisesResponse(Map<String, String> exercises) {
        Map<String, Map<String, Integer>> formatted = new HashMap<>();
        
        for (Map.Entry<String, String> entry : exercises.entrySet()) {
            String[] parts = entry.getValue().split(":");
            Map<String, Integer> scores = new HashMap<>();
            scores.put("challenger", Integer.parseInt(parts[0]));
            scores.put("opponent", Integer.parseInt(parts[1]));
            formatted.put(entry.getKey(), scores);
        }
        
        return formatted;
    }

    // Вспомогательный метод для подсчета общих очков
    private Map<String, Integer> calculateTotalScores(Map<String, String> exercises) {
        int totalChallenger = 0;
        int totalOpponent = 0;
        
        for (String scorePair : exercises.values()) {
            String[] parts = scorePair.split(":");
            totalChallenger += Integer.parseInt(parts[0]);
            totalOpponent += Integer.parseInt(parts[1]);
        }
        
        Map<String, Integer> totals = new HashMap<>();
        totals.put("challenger", totalChallenger);
        totals.put("opponent", totalOpponent);
        
        return totals;
    }
}