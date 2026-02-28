USE Tarea1DB;
GO

-- Borrar tablas si existen (orden inverso por dependencias)
DROP TABLE IF EXISTS tbl_usuario_rol;
DROP TABLE IF EXISTS tbl_roles;
DROP TABLE IF EXISTS tbl_usuarios;
GO

-- TABLA USUARIOS
CREATE TABLE tbl_usuarios(
    id_usuario          INT          IDENTITY(1,1) PRIMARY KEY,
    primer_nombre       VARCHAR(50)  NOT NULL,
    segundo_nombre      VARCHAR(50),
    primer_apellido     VARCHAR(50)  NOT NULL,
    segundo_apellido    VARCHAR(50),
    documento_identidad VARCHAR(20)  NOT NULL UNIQUE,
    email               VARCHAR(100) NOT NULL UNIQUE,
    telefono            VARCHAR(20),
    fecha_registro      DATE         NOT NULL DEFAULT GETDATE(),
    estado              VARCHAR(10)  NOT NULL DEFAULT 'activo' 
                        CHECK(estado IN('activo','inactivo'))
);
GO

-- TABLA ROLES
CREATE TABLE tbl_roles (
    id_rol  INT         IDENTITY(1,1) PRIMARY KEY,
    nombre  VARCHAR(20) NOT NULL UNIQUE 
            CHECK (nombre IN('estudiante','instructor'))
);
GO