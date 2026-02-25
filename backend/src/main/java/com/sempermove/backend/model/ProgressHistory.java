package com.sempermove.backend.model;

import jakarta.persistence.*;
import java.time.LocalDate;

@Entity
@Table(name = "progress_history")
public class ProgressHistory {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private Long userId;
    private LocalDate date = LocalDate.now();

    private int steps;
    private int pushUps;
    private int squats;
    private int plankSeconds;
    private int waterMl;

    public ProgressHistory() {}

    public ProgressHistory(Long userId, int steps, int pushUps, int squats, int plankSeconds, int waterMl) {
        this.userId = userId;
        this.steps = steps;
        this.pushUps = pushUps;
        this.squats = squats;
        this.plankSeconds = plankSeconds;
        this.waterMl = waterMl;
    }

    // --- getters & setters ---
    public Long getId() {
        return id;
    }

    public Long getUserId() {
        return userId;
    }

    public void setUserId(Long userId) {
        this.userId = userId;
    }

    public LocalDate getDate() {
        return date;
    }

    public void setDate(LocalDate date) {
        this.date = date;
    }

    public int getSteps() {
        return steps;
    }

    public void setSteps(int steps) {
        this.steps = steps;
    }

    public int getPushUps() {
        return pushUps;
    }

    public void setPushUps(int pushUps) {
        this.pushUps = pushUps;
    }

    public int getSquats() {
        return squats;
    }

    public void setSquats(int squats) {
        this.squats = squats;
    }

    public int getPlankSeconds() {
        return plankSeconds;
    }

    public void setPlankSeconds(int plankSeconds) {
        this.plankSeconds = plankSeconds;
    }

    public int getWaterMl() {
        return waterMl;
    }

    public void setWaterMl(int waterMl) {
        this.waterMl = waterMl;
    }
}
