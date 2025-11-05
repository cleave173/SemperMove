package com.sempermove.backend.controller;

import com.sempermove.backend.model.ProgressHistory;
import com.sempermove.backend.model.User;
import com.sempermove.backend.repository.ProgressHistoryRepository;
import com.sempermove.backend.repository.UserRepository;
import com.sempermove.backend.security.JwtUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/history")
public class ProgressHistoryController {

    @Autowired
    private ProgressHistoryRepository progressHistoryRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private JwtUtil jwtUtil;

    @PostMapping("/add")
    public ProgressHistory addProgress(@RequestHeader("Authorization") String token,
                                       @RequestBody ProgressHistory progress) {
        String email = jwtUtil.extractEmail(token.substring(7));
        User user = userRepository.findByEmail(email).orElseThrow();
        progress.setUserId(user.getId());
        return progressHistoryRepository.save(progress);
    }

    @GetMapping
    public List<ProgressHistory> getUserHistory(@RequestHeader("Authorization") String token) {
        String email = jwtUtil.extractEmail(token.substring(7));
        User user = userRepository.findByEmail(email).orElseThrow();
        return progressHistoryRepository.findByUserId(user.getId());
    }
}
