package com.elearning.hotelbooking.security.oauth2;

import com.elearning.hotelbooking.domain.User;
import com.elearning.hotelbooking.domain.enums.AuthProvider;
import com.elearning.hotelbooking.repository.UserRepository;
import com.elearning.hotelbooking.security.JwtUtil;
import jakarta.servlet.http.*;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.core.Authentication;
import org.springframework.security.oauth2.core.user.OAuth2User;
import org.springframework.security.web.authentication.AuthenticationSuccessHandler;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.Set;
import java.util.stream.Collectors;

@Component
public class OAuth2AuthenticationSuccessHandler implements AuthenticationSuccessHandler {

    private final JwtUtil jwtUtil;
    private final UserRepository users;
    private final String frontendUrl;

    public OAuth2AuthenticationSuccessHandler(
            JwtUtil jwtUtil,
            UserRepository users,
            @Value("${frontend.url:${FRONTEND_URL:http://localhost:3000}}") String frontendUrl
    ) {
        this.jwtUtil = jwtUtil;
        this.users = users;
        this.frontendUrl = frontendUrl;
    }

    @Override
    public void onAuthenticationSuccess(
            HttpServletRequest request,
            HttpServletResponse response,
            Authentication authentication
    ) throws IOException {

        OAuth2User oauthUser = (OAuth2User) authentication.getPrincipal();

        String email = ((String) oauthUser.getAttributes().get("email")).toLowerCase();
        String sub = (String) oauthUser.getAttributes().get("sub");
        String givenName = (String) oauthUser.getAttributes().get("given_name");
        String familyName = (String) oauthUser.getAttributes().get("family_name");
        String imageUrl = (String) oauthUser.getAttributes().get("picture");

        if (email == null || sub == null) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid OAuth2 user data");
            return;
        }

        // 🔹 Buscar o crear usuario
        User user = users.findByEmail(email)
                .orElseGet(() -> {
                    User newUser = new User();
                    newUser.setEmail(email);
                    newUser.setUsername(email); // por ahora
                    newUser.setGivenName(givenName);
                    newUser.setFamilyName(familyName);
                    newUser.setImageUrl(imageUrl);
                    newUser.setProvider(AuthProvider.GOOGLE);
                    newUser.setProviderSub(sub);
                    newUser.setEnabled(true);
                    return users.save(newUser);
                });

        Set<String> roles = user.getRoles()
                .stream()
                .map(r -> r.getName())
                .collect(Collectors.toSet());

        String token = jwtUtil.generateToken(
                user.getUsername(),
                roles,
                user.getUuid()
        );

        String encodedToken = URLEncoder.encode(token, StandardCharsets.UTF_8);
        String targetUrl = frontendUrl + "/oauth2/success?token=" + encodedToken;

        response.sendRedirect(targetUrl);
    }
}
