-- ==============================================================================
-- FERIA SEGURA HUAMANGA (FeriaSegura)
-- Migración 002: Autenticación Centralizada y ACL
-- Tareas Jira: FSH-22, FSH-23, FSH-24, FSH-27, FSH-36
-- ==============================================================================

-- 1. Tabla Central de Usuarios (Autenticación Unificada)
CREATE TABLE IF NOT EXISTS auth_acl.usuarios (
    id_usuario UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    identificador_login VARCHAR(100) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    tipo_usuario VARCHAR(30) NOT NULL,
    estado_cuenta VARCHAR(20) NOT NULL DEFAULT 'HABILITADA',
    ultimo_login TIMESTAMPTZ NULL,
    creado_en TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    actualizado_en TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT uq_usuarios_identificador UNIQUE (identificador_login),
    CONSTRAINT chk_usuarios_tipo CHECK (tipo_usuario IN ('COMERCIANTE', 'FUNCIONARIO_INTERNO')),
    CONSTRAINT chk_usuarios_estado CHECK (estado_cuenta IN ('HABILITADA', 'DESHABILITADA', 'BLOQUEADA'))
);

COMMENT ON TABLE auth_acl.usuarios IS 'Punto único y centralizado de autenticación para todo usuario del sistema';
COMMENT ON COLUMN auth_acl.usuarios.identificador_login IS 'DNI para comerciantes (8 dígitos) o usuario institucional/correo para funcionarios';

-- 2. Perfil de Comerciante (Extensión 1:0..1)
CREATE TABLE IF NOT EXISTS auth_acl.comerciante_perfil (
    id_comerciante UUID PRIMARY KEY,
    dni CHAR(8) NOT NULL,
    nombres VARCHAR(100) NOT NULL,
    apellidos VARCHAR(100) NOT NULL,
    telefono VARCHAR(15) NOT NULL,
    domicilio VARCHAR(255) NOT NULL,
    estado_padron VARCHAR(20) NOT NULL DEFAULT 'NUEVO',
    coincide_padron_historico BOOLEAN NOT NULL DEFAULT FALSE,
    actualizado_en TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT fk_comerciante_usuario FOREIGN KEY (id_comerciante) 
        REFERENCES auth_acl.usuarios(id_usuario) ON DELETE RESTRICT,
    CONSTRAINT uq_comerciante_dni UNIQUE (dni),
    CONSTRAINT chk_comerciante_dni_formato CHECK (dni ~ '^[0-9]{8}$'),
    CONSTRAINT chk_comerciante_telefono CHECK (telefono ~ '^[0-9]{7,15}$'),
    CONSTRAINT chk_comerciante_estado_padron CHECK (estado_padron IN ('NUEVO', 'REGULAR', 'OBSERVADO'))
);

COMMENT ON TABLE auth_acl.comerciante_perfil IS 'Datos personales y de contacto específicos del comerciante empadronado';

-- 3. Perfil de Funcionario Municipal (Extensión 1:0..1)
CREATE TABLE IF NOT EXISTS auth_acl.funcionario_perfil (
    id_funcionario UUID PRIMARY KEY,
    dni CHAR(8) NOT NULL,
    nombres VARCHAR(100) NOT NULL,
    apellidos VARCHAR(100) NOT NULL,
    cargo VARCHAR(100) NOT NULL,
    area_municipal VARCHAR(50) NOT NULL,
    actualizado_en TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT fk_funcionario_usuario FOREIGN KEY (id_funcionario) 
        REFERENCES auth_acl.usuarios(id_usuario) ON DELETE RESTRICT,
    CONSTRAINT uq_funcionario_dni UNIQUE (dni),
    CONSTRAINT chk_funcionario_dni_formato CHECK (dni ~ '^[0-9]{8}$'),
    CONSTRAINT chk_funcionario_area CHECK (area_municipal IN ('ADMINISTRACION', 'TESORERIA', 'DEFENSA_CIVIL', 'FISCALIZACION'))
);

COMMENT ON TABLE auth_acl.funcionario_perfil IS 'Datos institucionales de funcionarios municipales';

-- 4. Catálogo de Roles
CREATE TABLE IF NOT EXISTS auth_acl.roles (
    id_rol SERIAL PRIMARY KEY,
    nombre_rol VARCHAR(50) NOT NULL,
    descripcion TEXT NOT NULL,
    creado_en TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT uq_roles_nombre UNIQUE (nombre_rol)
);

-- 5. Catálogo de Permisos Atómicos
CREATE TABLE IF NOT EXISTS auth_acl.permisos (
    id_permiso SERIAL PRIMARY KEY,
    codigo_permiso VARCHAR(80) NOT NULL,
    modulo VARCHAR(50) NOT NULL,
    descripcion TEXT NOT NULL,
    creado_en TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT uq_permisos_codigo UNIQUE (codigo_permiso)
);

-- 6. Asignación de Roles a Usuarios
CREATE TABLE IF NOT EXISTS auth_acl.usuario_roles (
    id_usuario UUID NOT NULL,
    id_rol INTEGER NOT NULL,
    asignado_por UUID NULL,
    fecha_asignacion TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT pk_usuario_roles PRIMARY KEY (id_usuario, id_rol),
    CONSTRAINT fk_usuario_roles_usuario FOREIGN KEY (id_usuario) 
        REFERENCES auth_acl.usuarios(id_usuario) ON DELETE CASCADE,
    CONSTRAINT fk_usuario_roles_rol FOREIGN KEY (id_rol) 
        REFERENCES auth_acl.roles(id_rol) ON DELETE CASCADE,
    CONSTRAINT fk_usuario_roles_asignador FOREIGN KEY (asignado_por) 
        REFERENCES auth_acl.usuarios(id_usuario) ON DELETE SET NULL
);

-- 7. Privilegios de Roles (Permisos asignados al Rol)
CREATE TABLE IF NOT EXISTS auth_acl.rol_permisos (
    id_rol INTEGER NOT NULL,
    id_permiso INTEGER NOT NULL,
    CONSTRAINT pk_rol_permisos PRIMARY KEY (id_rol, id_permiso),
    CONSTRAINT fk_rol_permisos_rol FOREIGN KEY (id_rol) 
        REFERENCES auth_acl.roles(id_rol) ON DELETE CASCADE,
    CONSTRAINT fk_rol_permisos_permiso FOREIGN KEY (id_permiso) 
        REFERENCES auth_acl.permisos(id_permiso) ON DELETE CASCADE
);

-- 8. Lista de Control de Acceso (ACL a nivel de recurso/fila)
CREATE TABLE IF NOT EXISTS auth_acl.recurso_acl (
    id_acl BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_usuario UUID NOT NULL,
    tipo_recurso VARCHAR(50) NOT NULL,
    id_recurso UUID NOT NULL,
    puede_leer BOOLEAN NOT NULL DEFAULT TRUE,
    puede_escribir BOOLEAN NOT NULL DEFAULT FALSE,
    puede_aprobar BOOLEAN NOT NULL DEFAULT FALSE,
    otorgado_en TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT fk_recurso_acl_usuario FOREIGN KEY (id_usuario) 
        REFERENCES auth_acl.usuarios(id_usuario) ON DELETE CASCADE,
    CONSTRAINT uq_recurso_acl_usuario_objeto UNIQUE (id_usuario, tipo_recurso, id_recurso),
    CONSTRAINT chk_recurso_acl_tipo CHECK (tipo_recurso IN ('FERIA', 'SECTOR', 'ACTA_INFRACCION', 'PUESTO'))
);

COMMENT ON TABLE auth_acl.recurso_acl IS 'Reglas de acceso granular sobre instancias específicas de recursos del negocio';

-- 9. Control de Sesiones y Tokens de Acceso
CREATE TABLE IF NOT EXISTS auth_acl.sesion_tokens (
    id_sesion UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_usuario UUID NOT NULL,
    token_hash VARCHAR(64) NOT NULL,
    ip_origen INET NOT NULL,
    user_agent TEXT NULL,
    expira_en TIMESTAMPTZ NOT NULL,
    revocado BOOLEAN NOT NULL DEFAULT FALSE,
    creado_en TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT fk_sesion_tokens_usuario FOREIGN KEY (id_usuario) 
        REFERENCES auth_acl.usuarios(id_usuario) ON DELETE CASCADE,
    CONSTRAINT uq_sesion_tokens_hash UNIQUE (token_hash)
);

COMMENT ON TABLE auth_acl.sesion_tokens IS 'Control e invalidación de credenciales temporales de sesión (FSH-22)';
