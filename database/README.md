# Base de datos — Integry DT

## Motor local detectado
- Servicio: `MySQL267`
- Host previsto: `127.0.0.1`
- Puerto: `3306`
- Cliente: `C:\Program Files\MySQL\MySQL Server 26.7\bin\mysql.exe`
- Base: `integry_dt`
- Charset: `utf8mb4`

## Estructura
- `migrations/000_create_database.sql`: crea la base y registro de migraciones.
- `migrations/001_core_saas.sql`: tenants, usuarios, membresías, RBAC y dispositivos.
- `migrations/002_gadgets_jobs_audit.sql`: gadgets, tools, Jobs, notificaciones y auditoría.
- `seeds/001_development_seed.sql`: tenant, roles, permisos y catálogo de desarrollo.
- `scripts/Invoke-MySqlMigrations.ps1`: aplica migraciones y opcionalmente seed.
- `scripts/Test-DatabaseSchema.ps1`: validación básica de estructura/datos.

## Credenciales
No se guardan contraseñas MySQL en Git. Configure la sesión PowerShell:

```powershell
$env:INTEGRY_DB_HOST='127.0.0.1'
$env:INTEGRY_DB_PORT='3306'
$env:INTEGRY_DB_USER='integry_dev'
$env:INTEGRY_DB_PASSWORD='...'
```

Para aplicar migraciones y seed:

```powershell
.\database\scripts\Invoke-MySqlMigrations.ps1 -IncludeSeed
```

Para validar:

```powershell
.\database\scripts\Test-DatabaseSchema.ps1
```

## Seed de usuario
El usuario `admin@integrydt.local` se crea con `password_hash='DEV_PASSWORD_NOT_INITIALIZED'` deliberadamente. No es una contraseña utilizable. En Fase 2 el Backend deberá generar el hash real con el algoritmo de autenticación elegido; así evitamos introducir una contraseña conocida y reutilizable en el repositorio.

## Reglas multiempresa
- Los recursos empresariales se relacionan con `company_id`.
- Membresías impiden duplicar usuario dentro de una empresa.
- Devices son únicos por `(company_id, machine_key)`.
- Herramientas y gadgets se habilitan mediante tablas de política por empresa.
- Jobs llevan `company_id` y referencias al usuario, equipo, tool, gadget y versión exacta.
- El Backend deberá reforzar que todas esas referencias pertenezcan al mismo tenant; las FK por sí solas no sustituyen esa validación de negocio.

## Estado de validación local
MySQL está activo, pero `root` exige contraseña y no existe una credencial disponible en el proyecto. Por seguridad no se intenta recuperar ni evadir esa contraseña. Una vez configuradas credenciales válidas en variables de entorno se pueden ejecutar los dos scripts anteriores para validar el esquema real.