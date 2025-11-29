package com.elearning.hotelbooking.repository;

import com.elearning.hotelbooking.domain.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByEmail (String email);
    Optional<User> findByUsername (String username);
    boolean existsByEmail(String email);
    boolean existsByUsername(String username);
    Optional<User> findByUuid(UUID uuid);
}
