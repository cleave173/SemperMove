package com.sempermove.backend.repository;

import com.sempermove.backend.model.Duel;
import com.sempermove.backend.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface DuelRepository extends JpaRepository<Duel, Long> {
    
    List<Duel> findByChallengerOrOpponent(User challenger, User opponent);
    
    List<Duel> findByChallengerAndStatus(User challenger, String status);
    
    List<Duel> findByOpponentAndStatus(User opponent, String status);
    
    List<Duel> findByStatus(String status);
    
    @Query("SELECT d FROM Duel d WHERE (d.challenger = :user OR d.opponent = :user) AND d.status = 'IN_PROGRESS'")
    List<Duel> findActiveDuelsByUser(@Param("user") User user);
    
    Optional<Duel> findByIdAndStatus(Long id, String status);
    
    List<Duel> findByChallenger(User challenger);
    
    List<Duel> findByOpponent(User opponent);
    
    List<Duel> findByChallengerAndOpponent(User challenger, User opponent);
    
    List<Duel> findByChallengerAndOpponentAndStatus(User challenger, User opponent, String status);
}