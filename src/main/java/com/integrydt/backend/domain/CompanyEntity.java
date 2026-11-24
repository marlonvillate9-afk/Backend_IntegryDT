package com.integrydt.backend.domain;

import jakarta.persistence.*;

@Entity
@Table(name="companies")
public class CompanyEntity {
    @Id @Column(length=36) private String id;
    @Column(nullable=false) private String name;
    @Column(nullable=false,unique=true) private String slug;
    @Column(nullable=false) private String status;
    public String getId(){return id;} public String getName(){return name;} public String getSlug(){return slug;} public String getStatus(){return status;}
}
