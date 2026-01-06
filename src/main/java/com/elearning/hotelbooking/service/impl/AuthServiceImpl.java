package com.elearning.hotelbooking.service.impl;

import com.elearning.hotelbooking.domain.Role;
import com.elearning.hotelbooking.domain.User;
import com.elearning.hotelbooking.domain.enums.AuthProvider;
import com.elearning.hotelbooking.dto.*;
import com.elearning.hotelbooking.repository.RoleRepository;
import com.elearning.hotelbooking.repository.UserRepository;
import com.elearning.hotelbooking.security.JwtUtil;
import com.elearning.hotelbooking.service.AuthService;
import org.springframework.security.authentication.*;
import org.springframework.security.core.Authentication;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.stream.Collectors;

@Service
public class AuthServiceImpl implements AuthService {

    private final UserRepository users;
    private final RoleRepository roles;
    private final PasswordEncoder encoder;
    private final AuthenticationManager authManager;
    private final JwtUtil jwt;

    public AuthServiceImpl(UserRepository users, RoleRepository roles,
                           PasswordEncoder encoder, AuthenticationManager authManager, JwtUtil jwt) {
        this.users = users;
        this.roles = roles;
        this.encoder = encoder;
        this.authManager = authManager;
        this.jwt = jwt;
    }

    @Override
    public AuthResponse register(RegisterRequest r) {
        if (users.existsByEmail(r.email())) {
            throw new IllegalArgumentException("Email already in use");
        }
        if (users.existsByUsername(r.username())) {
            throw new IllegalArgumentException("Username already in use");
        }

        User u = new User();
        u.setUuid(UUID.randomUUID());
        u.setEmail(r.email().toLowerCase());
        u.setUsername(r.username());
        u.setPasswordHash(encoder.encode(r.password()));
        u.setGivenName(r.givenName());
        u.setFamilyName(r.familyName());
        u.setProvider(AuthProvider.LOCAL);
        u.setEnabled(true);

        Role userRole = roles.findByName("ROLE_USER")
                .orElseThrow(() -> new IllegalStateException("ROLE_USER not seeded"));
        u.getRoles().add(userRole);

        users.save(u);

        var roleNames = u.getRoles().stream().map(Role::getName).collect(Collectors.toSet());
        String token = jwt.generateToken(u.getUsername(), roleNames, u.getUuid());

        return new AuthResponse(token, AuthResponse.BEARER, getExpMs(), u.getUuid(), u.getUsername(), u.getEmail(), roleNames);
    }

    @Override
    public AuthResponse login(LoginRequest req) {
        Authentication auth = new UsernamePasswordAuthenticationToken(req.usernameOrEmail(), req.password());
        authManager.authenticate(auth);

        User u = users.findByUsername(req.usernameOrEmail())
                .or(() -> users.findByEmail(req.usernameOrEmail()))
                .orElseThrow(() -> new IllegalArgumentException("Invalid credentials"));

        var roleNames = u.getRoles().stream().map(Role::getName).collect(Collectors.toSet());
        String token = jwt.generateToken(u.getUsername(), roleNames, u.getUuid());

        return new AuthResponse(token, AuthResponse.BEARER, getExpMs(), u.getUuid(), u.getUsername(), u.getEmail(), roleNames);
    }

    private long getExpMs() {
        // lo tomamos de application.yml; ya lo usa JwtUtil internamente para generar el token
        // devolvemos un valor consistente para el cliente
        return 3600000L;
    }
}