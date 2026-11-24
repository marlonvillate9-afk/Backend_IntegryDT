package com.integrydt.backend.domain;

import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

public interface CompanyRepository extends JpaRepository<CompanyEntity,String> {
    Optional<CompanyEntity> findBySlug(String slug);
}
