# Integry DT Backend Java

Backend paralelo de Integry DT compatible con las funcionalidades implementadas hasta Fase 6.

## Stack

- Java 21 LTS (Temurin)
- Spring Boot 3.5
- Spring Security + JWT
- Spring Data JPA para el modelo persistente
- `JdbcTemplate` para consultas multi-tabla, JSON y el motor de Jobs sobre el esquema existente
- MySQL `integry_dt`
- WebSocket compatible con `Client Integry DT`

El esquema sigue siendo propiedad de las migraciones SQL. Hibernate usa `ddl-auto: none`; JPA no crea ni altera tablas.

## Compatibilidad

El backend conserva los contratos HTTP/WebSocket usados por Frontend Web y Client Integry DT:

- autenticación multiempresa y RBAC
- dispositivos y enrollment
- catálogo y administración de gadgets
- Jobs persistentes, eventos, resultados y cancelación
- paquetes firmados y cache verificada en Client
- notificaciones
- repositorios Git
- SFTP
- scripts PowerShell aprobados por hash
- screen recorder y artefactos
- automatización de clic/teclado/hotkeys
- auditoría

Las migraciones `000` a `008`, seed y scripts auxiliares están en `database/`.

## Toolchain local

```text
JAVA_HOME=C:\Users\user\Tools\Java\jdk-21
MAVEN_HOME=C:\Users\user\Tools\Maven\apache-maven-3.9.16
```

Los scripts del proyecto fijan estas rutas explícitamente para no usar accidentalmente el Java 16 heredado del sistema.

## Compilar

```powershell
.\scripts\Build.ps1
```

## Ejecutar

```powershell
.\scripts\Run-Api.ps1
```

Escucha en `http://127.0.0.1:5080`.

No ejecutar simultáneamente el Backend .NET y `backend_java` en el puerto 5080.
