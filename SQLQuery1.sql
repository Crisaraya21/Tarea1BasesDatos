USE Tarea1DB;
GO

-- Borrar tablas si existen (orden inverso por dependencias)
DROP TABLE IF EXISTS tbl_ediciones;
DROP TABLE IF EXISTS tbl_usuario_rol;
DROP TABLE IF EXISTS tbl_curso_instructor;
DROP TABLE IF EXISTS tbl_roles;
DROP TABLE IF EXISTS tbl_usuarios;
DROP TABLE IF EXISTS tbl_cursos;




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
    id_rol  INT     IDENTITY(1,1) PRIMARY KEY,
    nombre  VARCHAR(20) NOT NULL UNIQUE 
            CHECK (nombre IN('estudiante','instructor'))
);
GO
--TABLA DE USUARIO ROL(RELACION ESTUDIANTE CON INSTRUCTOR)

CREATE TABLE tbl_usuario_rol(
id_usuario INT NOT NULL,
id_rol INT NOT NULL,
PRIMARY KEY (id_usuario,id_rol),
FOREIGN KEY(id_usuario) REFERENCES tbl_usuarios(id_usuario),
FOREIGN KEY(id_rol) REFERENCES tbl_roles(id_rol)
);
GO

--Tabla de cursos
CREATE TABLE tbl_cursos (
    id_curso     INT           IDENTITY(1,1) PRIMARY KEY,
    codigo       VARCHAR(20)   NOT NULL UNIQUE,
    nombre       VARCHAR(100)  NOT NULL,
    descripcion  TEXT,
    duracion_sem INT           NOT NULL,
    precio       DECIMAL(10,2) NOT NULL,
    nivel        VARCHAR(15)   NOT NULL
                 CHECK (nivel IN ('basico','intermedio','avanzado')),
    estado       VARCHAR(10)   NOT NULL DEFAULT 'activo' CHECK (estado IN ('activo','cerrado'))
);
GO   

-- TABLA CURSO_INSTRUCTOR 
CREATE TABLE tbl_curso_instructor (
    id_curso    INT  NOT NULL,
    id_usuario  INT  NOT NULL,
    PRIMARY KEY (id_curso, id_usuario),
    FOREIGN KEY (id_curso)   REFERENCES tbl_cursos(id_curso),
    FOREIGN KEY (id_usuario) REFERENCES tbl_usuarios(id_usuario)
);
GO


CREATE TABLE tbl_ediciones(
    id_edicion   INT         IDENTITY(1,1) PRIMARY KEY,
    id_curso INT  NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin    DATE NOT NULL,
    cupo_maximo  INT NOT NULL, 
    modalidad  VARCHAR(10) NOT NULL CHECK(modalidad IN('virtual','hibrido')),
    CHECK(fecha_inicio<fecha_fin),
    FOREIGN KEY(id_curso) REFERENCES tbl_cursos(id_curso)
    );
    GO





    ----INFORMES-------
    SELECT 
    tbl_cursos.codigo,
    tbl_cursos.nombre AS Curso,
    tbl_usuarios.primer_nombre + ' ' + tbl_usuarios.primer_apellido AS instructor
    FROM tbl_cursos
    JOIN tbl_curso_instructor ON tbl_cursos.id_curso = tbl_curso_instructor.id_curso
    JOIN tbl_usuarios ON tbl_curso_instructor.id_usuario = tbl_usuarios.id_usuario
    ;
GO

SELECT 

tbl_ediciones.cupo_maximo * tbl_cursos.precio AS ingreso_proyectado
FROM tbl_cursos
JOIN tbl_ediciones ON tbl_cursos.id_curso = tbl_ediciones.id_curso

;
GO




    



