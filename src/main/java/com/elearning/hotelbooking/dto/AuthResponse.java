package com.elearning.hotelbooking.dto;

import java.util.Set;
import java.util.UUID;

public record AuthResponse (
        String accessToken,
        String tokenType,
        long expiresInMs,
        UUID userUuid,
        String username,
        String email,
        Set<String> roles
){
    public static final String BEARER = "Bearer";
}
