package com.sempermove.backend.repository;

import com.sempermove.backend.model.ProgressHistory;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ProgressHistoryRepository extends JpaRepository<ProgressHistory, Long> {
    List<ProgressHistory> findByUserId(Long userId);
}
