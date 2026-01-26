package com.elearning.hotelbooking.security.oauth2;

import com.elearning.hotelbooking.domain.Role;
import com.elearning.hotelbooking.domain.User;
import com.elearning.hotelbooking.domain.enums.AuthProvider;
import com.elearning.hotelbooking.repository.RoleRepository;
import com.elearning.hotelbooking.repository.UserRepository;
import jakarta.transaction.Transactional;
import org.springframework.security.oauth2.client.userinfo.DefaultOAuth2UserService;
import org.springframework.security.oauth2.client.userinfo.OAuth2UserRequest;
import org.springframework.security.oauth2.core.user.OAuth2User;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
public class CustomOAuth2UserService extends DefaultOAuth2UserService {

    private final UserRepository users;
    private final RoleRepository roles;

    public CustomOAuth2UserService(UserRepository users, RoleRepository roles) {
        this.users = users;
        this.roles = roles;
    }

    @Override
    @Transactional
    public OAuth2User loadUser(OAuth2UserRequest userRequest) {
        OAuth2User oauth2User = super.loadUser(userRequest);
        String registrationId = userRequest.getClientRegistration().getRegistrationId();

        OAuth2UserInfo userInfo;
        if ("google".equalsIgnoreCase(registrationId)) {
            userInfo = new GoogleOAuth2UserInfo(oauth2User.getAttributes());
        } else {
            throw new IllegalArgumentException("Unsupported provider: " + registrationId);
        }

        processOAuth2User(userInfo);

        return oauth2User;
    }

    private void processOAuth2User(OAuth2UserInfo userInfo) {
        String email = userInfo.getEmail();
        if (email == null || email.isBlank()) {
            throw new IllegalArgumentException("Email not found from OAuth2 provider");
        }

        var opt = users.findByEmail(email.toLowerCase());

        if (opt.isPresent()) {
            User existing = opt.get();

            if (existing.getProvider() == AuthProvider.LOCAL) {
                existing.setProvider(AuthProvider.GOOGLE);
            }

            existing.setProviderSub(userInfo.getId());
            existing.setGivenName(userInfo.getGivenName());
            existing.setFamilyName(userInfo.getFamilyName());
            existing.setImageUrl(userInfo.getImageUrl());

            users.save(existing);
            return;
        }

        // Crear nuevo usuario
        User user = new User();
        user.setUuid(UUID.randomUUID());
        user.setEmail(email.toLowerCase());

        String base = email.split("@")[0];
        String username = base;
        int i = 0;
        while (users.existsByUsername(username)) {
            i++;
            username = base + i;
        }
        user.setUsername(username);

        user.setGivenName(userInfo.getGivenName());
        user.setFamilyName(userInfo.getFamilyName());
        user.setImageUrl(userInfo.getImageUrl());
        user.setProvider(AuthProvider.GOOGLE);
        user.setProviderSub(userInfo.getId());
        user.setEnabled(true);

        Role roleUser = roles.findByName("ROLE_USER")
                .orElseThrow(() -> new IllegalStateException("ROLE_USER not seeded"));
        user.getRoles().add(roleUser);

        users.save(user);
    }
}
