package com.elearning.hotelbooking.service;

import com.elearning.hotelbooking.dto.*;

public interface AuthService {
    AuthResponse register(RegisterRequest request);
    AuthResponse login(LoginRequest request);
}