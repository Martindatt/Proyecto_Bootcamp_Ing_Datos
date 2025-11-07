-- =========================================================
-- Semana 4 – Modelo Estrella (DW) 
-- Dimensiones: dim_usuario, dim_producto, dim_fecha
-- Hechos: fact_ventas_dw
-- =========================================================

-- Limpieza segura
DROP TABLE IF EXISTS dim_usuario;
DROP TABLE IF EXISTS dim_producto;
DROP TABLE IF EXISTS fact_ventas_dw;
DROP TABLE IF EXISTS dim_fecha;

-- ===================
-- DIMENSIONES
-- ===================

-- 1) Usuarios  (ajustada a tus columnas reales)
CREATE TABLE dim_usuario (
    user_id     INTEGER PRIMARY KEY,
    nombre      TEXT,
    apellido    TEXT,
    email       TEXT,
    ciudad      TEXT,
    provincia   TEXT,
    cp          TEXT,
    direccion   TEXT
);

INSERT INTO dim_usuario (user_id, nombre, apellido, email, ciudad, provincia, cp, direccion)
SELECT DISTINCT
    u.user_id,
    u.nombre,
    u.apellido,
    u.email,
    u.ciudad,
    u.provincia,
    u.cp,
    u.direccion
FROM v_users u
WHERE u.user_id IS NOT NULL;

-- 2) Productos
CREATE TABLE dim_producto (
    product_id      INTEGER PRIMARY KEY,
    nombre_producto TEXT,
    categoria       TEXT,
    marca           TEXT
);

INSERT INTO dim_producto (product_id, nombre_producto, categoria, marca)
SELECT DISTINCT
    p.product_id,
    p.titulo AS nombre_producto,
    p.categoria,
    p.marca
FROM v_products p
WHERE p.product_id IS NOT NULL;

-- ===================
-- TABLA DE HECHOS (crear y poblar ANTES de dim_fecha)
-- ===================
CREATE TABLE fact_ventas_dw (
    cart_id            INTEGER,
    user_id            INTEGER NOT NULL,
    product_id         INTEGER NOT NULL,
    categoria          TEXT,
    marca              TEXT,
    cantidad           INTEGER NOT NULL,
    precio_unitario    DOUBLE NOT NULL,
    descuento_pct      DOUBLE,
    ingreso_bruto      DOUBLE NOT NULL,
    descuento_importe  DOUBLE NOT NULL,
    ingreso_neto       DOUBLE NOT NULL,
    fecha_proceso      DATE NOT NULL
);

INSERT INTO fact_ventas_dw (
    cart_id, user_id, product_id, categoria, marca,
    cantidad, precio_unitario, descuento_pct,
    ingreso_bruto, descuento_importe, ingreso_neto,
    fecha_proceso
)
SELECT
    f.cart_id,
    f.user_id,
    f.product_id,
    f.categoria,
    f.marca,
    f.cantidad,
    f.precio_unitario                                   AS precio_unitario,
    COALESCE(f.descuento_pct, 0)               AS descuento_pct,
    ROUND(f.precio_unitario * f.cantidad, 2)            AS ingreso_bruto,
    ROUND((f.precio_unitario * f.cantidad) - COALESCE(f.total_con_descuento,0), 2) AS descuento_importe,
    ROUND(COALESCE(f.total_con_descuento,0), 2)            AS ingreso_neto,
    f.fecha_proceso
FROM fact_ventas f
JOIN dim_usuario  du ON du.user_id    = f.user_id
JOIN dim_producto dp ON dp.product_id = f.product_id;

-- ===================
-- 3) DIMENSIÓN FECHA (después de tener fact_ventas_dw)
-- ===================
CREATE TABLE dim_fecha (
    fecha_id    DATE PRIMARY KEY,
    anio        INTEGER,
    mes         INTEGER,
    nombre_mes  TEXT,
    trimestre   INTEGER,
    dia         INTEGER,
    dia_semana  TEXT
);

INSERT INTO dim_fecha (fecha_id, anio, mes, nombre_mes, trimestre, dia, dia_semana)
SELECT DISTINCT
    f.fecha_proceso                                                   AS fecha_id,
    EXTRACT(YEAR  FROM f.fecha_proceso)::INT                         AS anio,
    EXTRACT(MONTH FROM f.fecha_proceso)::INT                         AS mes,
    strftime(f.fecha_proceso, '%B')                                  AS nombre_mes,
    ((EXTRACT(MONTH FROM f.fecha_proceso)::INT - 1) / 3) + 1         AS trimestre,
    EXTRACT(DAY   FROM f.fecha_proceso)::INT                         AS dia,
    strftime(f.fecha_proceso, '%A')                                  AS dia_semana
FROM fact_ventas_dw f
WHERE f.fecha_proceso IS NOT NULL;


