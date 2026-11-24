package com.integrydt.backend.domain;

import jakarta.persistence.*;

@Entity
@Table(name="users")
public class UserEntity {
    @Id @Column(length=36) private String id;
    @Column(nullable=false,unique=true,length=254) private String email;
    @Column(name="password_hash",nullable=false) private String passwordHash;
    @Column(name="display_name",nullable=false) private String displayName;
    @Column(nullable=false) private String status;
    public String getId(){return id;} public String getEmail(){return email;} public String getPasswordHash(){return passwordHash;} public String getDisplayName(){return displayName;} public String getStatus(){return status;}
}
