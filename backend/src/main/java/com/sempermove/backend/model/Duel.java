package com.sempermove.backend.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

/**
 * Дуэль моделі
 * Екі қолданушы арасындағы бәсекелестікті басқарады
 */
@Entity
@Table(name = "duels")
public class Duel {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "challenger_id", nullable = false)
    private User challenger;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "opponent_id", nullable = false)
    private User opponent;

    @Column(nullable = false)
    private String status = "IN_PROGRESS";

    @Column
    private String winner;

    // Поле для ОДНОЙ категории
    @Column(name = "exercise_category")
    private String exerciseCategory;

    // Поля для очков при ОДНОЙ категории
    @Column(name = "challenger_score")
    private Integer challengerScore = 0;

    @Column(name = "opponent_score")
    private Integer opponentScore = 0;

    // Поле для НЕСКОЛЬКИХ категорий в формате JSON
    @Column(columnDefinition = "TEXT")
    private String exercises; // Формат: {"pushups": "30:25", "squats": "40:35"}

    @Column(name = "created_at")
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(name = "updated_at")
    private LocalDateTime updatedAt = LocalDateTime.now();

    public Duel() {}

    // Конструктор для одной категории
    public Duel(User challenger, User opponent, String exerciseCategory) {
        this.challenger = challenger;
        this.opponent = opponent;
        this.exerciseCategory = exerciseCategory;
        this.status = "IN_PROGRESS";
        this.challengerScore = 0;
        this.opponentScore = 0;
        this.createdAt = LocalDateTime.now();
        this.updatedAt = LocalDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        this.updatedAt = LocalDateTime.now();
    }

    // --- Getters / Setters ---
    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public User getChallenger() {
        return challenger;
    }

    public void setChallenger(User challenger) {
        this.challenger = challenger;
    }

    public User getOpponent() {
        return opponent;
    }

    public void setOpponent(User opponent) {
        this.opponent = opponent;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public String getWinner() {
        return winner;
    }

    public void setWinner(String winner) {
        this.winner = winner;
    }

    public String getExerciseCategory() {
        return exerciseCategory;
    }

    public void setExerciseCategory(String exerciseCategory) {
        this.exerciseCategory = exerciseCategory;
    }

    public Integer getChallengerScore() {
        return challengerScore != null ? challengerScore : 0;
    }

    public void setChallengerScore(Integer challengerScore) {
        this.challengerScore = challengerScore;
    }

    public Integer getOpponentScore() {
        return opponentScore != null ? opponentScore : 0;
    }

    public void setOpponentScore(Integer opponentScore) {
        this.opponentScore = opponentScore;
    }

    public String getExercises() {
        return exercises;
    }

    public void setExercises(String exercises) {
        this.exercises = exercises;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(LocalDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }

    // --- Вспомогательные методы для работы с exercises ---

    // Получить exercises как Map
    public Map<String, String> getExercisesMap() {
        if (exercises == null || exercises.trim().isEmpty()) {
            return new HashMap<>();
        }
        try {
            com.fasterxml.jackson.databind.ObjectMapper mapper = new com.fasterxml.jackson.databind.ObjectMapper();
            return mapper.readValue(exercises, 
                mapper.getTypeFactory().constructMapType(Map.class, String.class, String.class));
        } catch (Exception e) {
            return new HashMap<>();
        }
    }

    // Установить exercises из Map
    public void setExercisesMap(Map<String, String> exercisesMap) {
        try {
            com.fasterxml.jackson.databind.ObjectMapper mapper = new com.fasterxml.jackson.databind.ObjectMapper();
            this.exercises = mapper.writeValueAsString(exercisesMap);
        } catch (Exception e) {
            this.exercises = "{}";
        }
    }

    // Получить список категорий упражнений
    public java.util.List<String> getExerciseCategories() {
        if (isMultipleCategories()) {
            return new java.util.ArrayList<>(getExercisesMap().keySet());
        } else if (exerciseCategory != null) {
            return java.util.List.of(exerciseCategory);
        } else {
            return new java.util.ArrayList<>();
        }
    }

    // Проверить, это дуэль с несколькими категориями
    public boolean isMultipleCategories() {
        return exercises != null && !exercises.trim().isEmpty() && !exercises.equals("{}");
    }

    // Проверить, это дуэль с одной категорией
    public boolean isSingleCategory() {
        return exerciseCategory != null && !exerciseCategory.trim().isEmpty() && 
               (exercises == null || exercises.trim().isEmpty() || exercises.equals("{}"));
    }

    // Получить общие очки challenger
    public int getTotalChallengerScore() {
        if (isMultipleCategories()) {
            Map<String, String> exercisesMap = getExercisesMap();
            return exercisesMap.values().stream()
                    .mapToInt(score -> {
                        String[] parts = score.split(":");
                        return Integer.parseInt(parts[0]);
                    })
                    .sum();
        } else {
            return getChallengerScore();
        }
    }

    // Получить общие очки opponent
    public int getTotalOpponentScore() {
        if (isMultipleCategories()) {
            Map<String, String> exercisesMap = getExercisesMap();
            return exercisesMap.values().stream()
                    .mapToInt(score -> {
                        String[] parts = score.split(":");
                        return Integer.parseInt(parts[1]);
                    })
                    .sum();
        } else {
            return getOpponentScore();
        }
    }
}