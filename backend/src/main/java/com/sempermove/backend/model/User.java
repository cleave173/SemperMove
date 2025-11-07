package com.sempermove.backend.model;

import jakarta.persistence.*;
import java.util.HashSet;
import java.util.Set;

/**
 * Қолданушы моделі
 * Жүйедегі пайдаланушының барлық деректерін сақтайды
 */
@Entity
@Table(name = "users")
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String email;

    private String username;

    private String password;

    private int dailySteps = 0;
    private int pushUps = 0;
    private int squats = 0;
    private int plankSeconds = 0;
    private int waterMl = 0;

    @ManyToMany(fetch = FetchType.LAZY)
    @JoinTable(
            name = "user_friends",
            joinColumns = @JoinColumn(name = "user_id"),
            inverseJoinColumns = @JoinColumn(name = "friend_id")
    )
    private Set<User> friends = new HashSet<>();

    public User() {}

    public User(String email, String username, String password) {
        this.email = email;
        this.username = username;
        this.password = password;
    }

    // Getters & Setters
    public Long getId() { return id; }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }

    public String getPassword() { return password; }
    public void setPassword(String password) { this.password = password; }

    public int getDailySteps() { return dailySteps; }
    public void setDailySteps(int dailySteps) { this.dailySteps = dailySteps; }

    public int getPushUps() { return pushUps; }
    public void setPushUps(int pushUps) { this.pushUps = pushUps; }

    public int getSquats() { return squats; }
    public void setSquats(int squats) { this.squats = squats; }

    public int getPlankSeconds() { return plankSeconds; }
    public void setPlankSeconds(int plankSeconds) { this.plankSeconds = plankSeconds; }

    public int getWaterMl() { return waterMl; }
    public void setWaterMl(int waterMl) { this.waterMl = waterMl; }

    public Set<User> getFriends() { return friends; }
    public void setFriends(Set<User> friends) { this.friends = friends; }
}
