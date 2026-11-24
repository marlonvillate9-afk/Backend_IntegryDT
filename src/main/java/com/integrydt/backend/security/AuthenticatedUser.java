package com.integrydt.backend.security;

import java.util.Set;

public record AuthenticatedUser(String id,String email,String displayName,String companyId,String companySlug,Set<String> roles,Set<String> permissions) {}
