USE Tarea1DB;
GO

-- Borrar tablas si existen (orden inverso por dependencias)

-- Persona B
IF OBJECT_ID('trg_emitir_certificado',    'TR') IS NOT NULL DROP TRIGGER trg_emitir_certificado;
IF OBJECT_ID('trg_activar_inscripcion',   'TR') IS NOT NULL DROP TRIGGER trg_activar_inscripcion;
IF OBJECT_ID('trg_progreso_inscripcion',  'TR') IS NOT NULL DROP TRIGGER trg_progreso_inscripcion;
DROP TABLE IF EXISTS tbl_certificaciones;
DROP TABLE IF EXISTS tbl_calificaciones;
DROP TABLE IF EXISTS tbl_evaluaciones;
DROP TABLE IF EXISTS tbl_pagos;
DROP TABLE IF EXISTS tbl_inscripciones;

-- Persona A
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
    cupo_maximo  INT NOT NULL CHECK(cupo_maximo > 0), 
    modalidad  VARCHAR(10) NOT NULL CHECK(modalidad IN('virtual','hibrido')),
    CHECK(fecha_inicio<fecha_fin),
    FOREIGN KEY(id_curso) REFERENCES tbl_cursos(id_curso)
    );
    GO





-- ============================================================
-- PERSONA B: INSCRIPCIONES, PAGOS, EVALUACIONES, CERTIFICACIONES
-- ============================================================

-- TABLA INSCRIPCIONES
-- Intersección: depende de tbl_usuarios (estudiante) y tbl_ediciones (Persona A)
CREATE TABLE tbl_inscripciones (
    id_inscripcion   INT          IDENTITY(1,1) PRIMARY KEY,
    id_usuario       INT          NOT NULL,
    id_edicion       INT          NOT NULL,
    fecha_inscripcion DATE        NOT NULL DEFAULT GETDATE(),
    estado           VARCHAR(20)  NOT NULL DEFAULT 'pendiente_pago'
                     CHECK (estado IN ('pendiente_pago','activa','cancelada','finalizada')),
    progreso         DECIMAL(5,2) NOT NULL DEFAULT 0.00
                     CHECK (progreso BETWEEN 0 AND 100),
    UNIQUE (id_usuario, id_edicion),                          -- evita duplicados
    FOREIGN KEY (id_usuario) REFERENCES tbl_usuarios(id_usuario),
    FOREIGN KEY (id_edicion) REFERENCES tbl_ediciones(id_edicion)
);
GO

-- TABLA PAGOS
CREATE TABLE tbl_pagos (
    id_pago        INT           IDENTITY(1,1) PRIMARY KEY,
    id_inscripcion INT           NOT NULL,
    fecha          DATE          NOT NULL DEFAULT GETDATE(),
    monto          DECIMAL(10,2) NOT NULL CHECK (monto > 0),
    metodo_pago    VARCHAR(20)   NOT NULL
                   CHECK (metodo_pago IN ('tarjeta','transferencia','efectivo')),
    estado         VARCHAR(15)   NOT NULL DEFAULT 'pendiente'
                   CHECK (estado IN ('pendiente','aprobado','rechazado')),
    FOREIGN KEY (id_inscripcion) REFERENCES tbl_inscripciones(id_inscripcion)
);
GO

-- TABLA EVALUACIONES
CREATE TABLE tbl_evaluaciones (
    id_evaluacion INT          IDENTITY(1,1) PRIMARY KEY,
    id_edicion    INT          NOT NULL,
    nombre        VARCHAR(100) NOT NULL,
    tipo          VARCHAR(10)  NOT NULL
                  CHECK (tipo IN ('examen','proyecto','tarea')),
    peso          DECIMAL(5,2) NOT NULL CHECK (peso > 0 AND peso <= 100),
    FOREIGN KEY (id_edicion) REFERENCES tbl_ediciones(id_edicion)
);
GO

-- TABLA CALIFICACIONES (many-to-many: inscripcion <-> evaluacion)
CREATE TABLE tbl_calificaciones (
    id_inscripcion INT          NOT NULL,
    id_evaluacion  INT          NOT NULL,
    calificacion   DECIMAL(5,2) NOT NULL CHECK (calificacion BETWEEN 0 AND 100),
    PRIMARY KEY (id_inscripcion, id_evaluacion),
    FOREIGN KEY (id_inscripcion) REFERENCES tbl_inscripciones(id_inscripcion),
    FOREIGN KEY (id_evaluacion)  REFERENCES tbl_evaluaciones(id_evaluacion)
);
GO

-- TABLA CERTIFICACIONES (one-to-one con inscripcion finalizada y aprobada)
CREATE TABLE tbl_certificaciones (
    id_certificacion INT          IDENTITY(1,1) PRIMARY KEY,
    id_inscripcion   INT          NOT NULL UNIQUE,
    fecha_emision    DATE         NOT NULL DEFAULT GETDATE(),
    codigo_unico     VARCHAR(50)  NOT NULL UNIQUE
                     DEFAULT CAST(NEWID() AS VARCHAR(50)),   -- UUID verificable
    FOREIGN KEY (id_inscripcion) REFERENCES tbl_inscripciones(id_inscripcion)
);
GO

-- ============================================================
-- ÍNDICES PARA EFICIENCIA
-- ============================================================
CREATE INDEX idx_inscripciones_usuario  ON tbl_inscripciones (id_usuario);
CREATE INDEX idx_inscripciones_edicion  ON tbl_inscripciones (id_edicion);
CREATE INDEX idx_pagos_inscripcion      ON tbl_pagos         (id_inscripcion);
CREATE INDEX idx_evaluaciones_edicion   ON tbl_evaluaciones  (id_edicion);
CREATE INDEX idx_calificaciones_insc    ON tbl_calificaciones(id_inscripcion);
GO

-- ============================================================
-- TRIGGERS
-- ============================================================

-- TRIGGER 1: Activar inscripción cuando exista al menos un pago aprobado
--            La inscripción nace en 'pendiente_pago'; solo pasa a 'activa'
--            cuando se confirma al menos un pago aprobado.
CREATE TRIGGER trg_activar_inscripcion
ON tbl_pagos
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE tbl_inscripciones
    SET estado = 'activa'
    FROM tbl_inscripciones i
    INNER JOIN inserted ins ON i.id_inscripcion = ins.id_inscripcion
    WHERE ins.estado = 'aprobado'
      AND i.estado = 'pendiente_pago';  -- solo activa si estaba esperando pago
END;
GO

-- TRIGGER 2: Recalcular progreso y emitir certificado automáticamente
--            Progreso = suma ponderada de calificaciones obtenidas
--            Si progreso = 100% y nota_final >= 70 → genera certificado
CREATE TRIGGER trg_progreso_inscripcion
ON tbl_calificaciones
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Recalcular progreso: % de pesos evaluados respecto al total de la edición
    -- Se usa tbl_inscripciones.id_edicion (contexto externo) para evitar
    -- referenciar columna no agregada dentro del SELECT con SUM.
    UPDATE tbl_inscripciones
    SET progreso = (
        SELECT ISNULL(
            100.0 * SUM(e.peso) /
            NULLIF((SELECT SUM(e2.peso)
                    FROM tbl_evaluaciones e2
                    WHERE e2.id_edicion = tbl_inscripciones.id_edicion), 0)
        , 0)
        FROM tbl_calificaciones c
        JOIN tbl_evaluaciones e ON c.id_evaluacion = e.id_evaluacion
        WHERE c.id_inscripcion = tbl_inscripciones.id_inscripcion
    )
    WHERE id_inscripcion IN (SELECT DISTINCT id_inscripcion FROM inserted);

    -- Marcar como finalizada si progreso = 100%
    UPDATE tbl_inscripciones
    SET estado = 'finalizada'
    WHERE id_inscripcion IN (SELECT DISTINCT id_inscripcion FROM inserted)
      AND progreso = 100;
END;
GO

-- TRIGGER 3: Emitir certificado si inscripción finalizada y nota_final >= 70%
CREATE TRIGGER trg_emitir_certificado
ON tbl_inscripciones
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO tbl_certificaciones (id_inscripcion, codigo_unico)
    SELECT i.id_inscripcion,
           CAST(NEWID() AS VARCHAR(50))
    FROM inserted i
    JOIN deleted  d ON i.id_inscripcion = d.id_inscripcion
    WHERE i.estado = 'finalizada'
      AND d.estado <> 'finalizada'          -- solo cuando recién finaliza
      AND NOT EXISTS (
            SELECT 1 FROM tbl_certificaciones c
            WHERE c.id_inscripcion = i.id_inscripcion
      )
      AND (
            SELECT ISNULL(SUM(cal.calificacion * e.peso / 100.0), 0)
            FROM tbl_calificaciones cal
            JOIN tbl_evaluaciones e ON cal.id_evaluacion = e.id_evaluacion
            WHERE cal.id_inscripcion = i.id_inscripcion
      ) >= 70;
END;
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

-- Ingresos proyectados por edición (Persona A)
SELECT
    tbl_cursos.codigo,
    tbl_cursos.nombre                           AS curso,
    tbl_ediciones.id_edicion,
    tbl_ediciones.fecha_inicio,
    tbl_ediciones.cupo_maximo * tbl_cursos.precio AS ingreso_proyectado
FROM tbl_cursos
JOIN tbl_ediciones ON tbl_cursos.id_curso = tbl_ediciones.id_curso;
GO

-- Progreso por estudiante en cada edición (Persona B)
SELECT
    u.primer_nombre + ' ' + u.primer_apellido   AS estudiante,
    c.nombre                                    AS curso,
    e.fecha_inicio,
    i.estado                                    AS estado_inscripcion,
    i.progreso                                  AS progreso_pct
FROM tbl_inscripciones i
JOIN tbl_usuarios  u ON i.id_usuario  = u.id_usuario
JOIN tbl_ediciones e ON i.id_edicion  = e.id_edicion
JOIN tbl_cursos    c ON e.id_curso    = c.id_curso
ORDER BY c.nombre, estudiante;
GO

-- Calificaciones por estudiante y evaluación (Persona B)
SELECT
    u.primer_nombre + ' ' + u.primer_apellido   AS estudiante,
    c.nombre                                    AS curso,
    ev.nombre                                   AS evaluacion,
    ev.tipo,
    ev.peso                                     AS peso_pct,
    cal.calificacion
FROM tbl_calificaciones cal
JOIN tbl_inscripciones i  ON cal.id_inscripcion = i.id_inscripcion
JOIN tbl_evaluaciones  ev ON cal.id_evaluacion  = ev.id_evaluacion
JOIN tbl_usuarios      u  ON i.id_usuario       = u.id_usuario
JOIN tbl_ediciones     e  ON i.id_edicion       = e.id_edicion
JOIN tbl_cursos        c  ON e.id_curso         = c.id_curso
ORDER BY c.nombre, estudiante, ev.nombre;
GO

-- Pagos pendientes por inscripción (Persona B)
SELECT
    u.primer_nombre + ' ' + u.primer_apellido   AS estudiante,
    c.nombre                                    AS curso,
    p.fecha                                     AS fecha_pago,
    p.monto,
    p.metodo_pago,
    p.estado                                    AS estado_pago
FROM tbl_pagos p
JOIN tbl_inscripciones i ON p.id_inscripcion = i.id_inscripcion
JOIN tbl_usuarios      u ON i.id_usuario     = u.id_usuario
JOIN tbl_ediciones     e ON i.id_edicion     = e.id_edicion
JOIN tbl_cursos        c ON e.id_curso       = c.id_curso
WHERE p.estado = 'pendiente'
ORDER BY p.fecha;
GO

-- Ingresos reales por edición (pagos aprobados) (Persona B)
SELECT
    c.nombre                                    AS curso,
    e.id_edicion,
    e.fecha_inicio,
    SUM(p.monto)                                AS ingreso_real
FROM tbl_pagos p
JOIN tbl_inscripciones i ON p.id_inscripcion = i.id_inscripcion
JOIN tbl_ediciones     e ON i.id_edicion     = e.id_edicion
JOIN tbl_cursos        c ON e.id_curso       = c.id_curso
WHERE p.estado = 'aprobado'
GROUP BY c.nombre, e.id_edicion, e.fecha_inicio
ORDER BY e.fecha_inicio;
GO

-- Certificados emitidos (Persona B)
SELECT
    u.primer_nombre + ' ' + u.primer_apellido   AS estudiante,
    c.nombre                                    AS curso,
    cert.fecha_emision,
    cert.codigo_unico
FROM tbl_certificaciones cert
JOIN tbl_inscripciones i ON cert.id_inscripcion = i.id_inscripcion
JOIN tbl_usuarios      u ON i.id_usuario        = u.id_usuario
JOIN tbl_ediciones     e ON i.id_edicion        = e.id_edicion
JOIN tbl_cursos        c ON e.id_curso          = c.id_curso
ORDER BY cert.fecha_emision DESC;
GO
