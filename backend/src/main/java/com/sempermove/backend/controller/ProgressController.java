package com.sempermove.backend.controller;

import com.sempermove.backend.model.Duel;
import com.sempermove.backend.model.User;
import com.sempermove.backend.repository.DuelRepository;
import com.sempermove.backend.repository.UserRepository;
import com.sempermove.backend.security.JwtUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping("/api/progress")
public class ProgressController {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private DuelRepository duelRepository;

    @Autowired
    private JwtUtil jwtUtil;

    public static class ProgressRequest {
        public Integer dailySteps;
        public Integer pushUps;
        public Integer squats;
        public Integer plankSeconds;
        public Integer waterMl;
    }

    @GetMapping
    public ResponseEntity<?> getMyProgress(@RequestHeader(value = "Authorization", required = false) String authHeader) {
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            return ResponseEntity.status(401).body("Missing or invalid Authorization header");
        }

        String token = authHeader.substring(7);
        String email;
        try {
            email = jwtUtil.extractEmail(token);
        } catch (Exception e) {
            return ResponseEntity.status(401).body("Invalid token");
        }

        Optional<User> opt = userRepository.findByEmail(email);
        if (opt.isEmpty()) {
            return ResponseEntity.status(404).body("User not found");
        }

        return ResponseEntity.ok(opt.get());
    }

    @PostMapping("/update")
    public ResponseEntity<?> updateProgress(
            @RequestHeader(value = "Authorization", required = false) String authHeader,
            @RequestBody ProgressRequest request) {

        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            return ResponseEntity.status(401).body("Missing or invalid Authorization header");
        }

        String token = authHeader.substring(7);
        String email;
        try {
            email = jwtUtil.extractEmail(token); 
        } catch (Exception e) {
            return ResponseEntity.status(401).body("Invalid token");
        }

        Optional<User> opt = userRepository.findByEmail(email);
        if (opt.isEmpty()) {
            return ResponseEntity.status(404).body("User not found");
        }

        User user = opt.get();

        if (request.dailySteps != null) user.setDailySteps(request.dailySteps);
        if (request.pushUps != null) user.setPushUps(request.pushUps);
        if (request.squats != null) user.setSquats(request.squats);
        if (request.plankSeconds != null) user.setPlankSeconds(request.plankSeconds);
        if (request.waterMl != null) user.setWaterMl(request.waterMl);

        userRepository.save(user);

        // Автоматическая синхронизация активных дуэлей
        syncActiveDuels(user);

        return ResponseEntity.ok(user);
    }

    // Синхронизация очков в активных дуэлях с текущим прогрессом
    private void syncActiveDuels(User user) {
        List<Duel> activeDuels = duelRepository.findActiveDuelsByUser(user);
        
        for (Duel duel : activeDuels) {
            if (duel.isSingleCategory() && duel.getExerciseCategory() != null) {
                String category = duel.getExerciseCategory().toLowerCase();
                int userScore = 0;

                // Определяем очки пользователя по категории упражнения
                switch (category) {
                    case "pushups":
                        userScore = user.getPushUps();
                        break;
                    case "squats":
                        userScore = user.getSquats();
                        break;
                    case "plank":
                        userScore = user.getPlankSeconds();
                        break;
                    case "steps":
                        userScore = user.getDailySteps();
                        break;
                }

                // Обновляем очки в зависимости от роли пользователя
                if (duel.getChallenger().getId().equals(user.getId())) {
                    duel.setChallengerScore(userScore);
                } else if (duel.getOpponent().getId().equals(user.getId())) {
                    duel.setOpponentScore(userScore);
                }

                duelRepository.save(duel);
            }
        }
    }
}
