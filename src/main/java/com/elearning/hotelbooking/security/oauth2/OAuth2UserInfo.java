package com.elearning.hotelbooking.security.oauth2;

import java.util.Map;

public abstract class OAuth2UserInfo {
    protected Map<String, Object> attributes;

    public OAuth2UserInfo(Map<String, Object> attributes) {
        this.attributes = attributes;
    }

    public Map<String, Object> getAttributes() {
        return attributes;
    }

    public abstract String getId();

    public abstract String getEmail();

    public abstract String getName();

    public abstract String getGivenName();

    public abstract String getFamilyName();

    public abstract String getImageUrl();
}
