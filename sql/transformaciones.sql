/* 
TRANSFORMACIONES SQL – Semana 3 (DuckDB)
Proyecto: In-nova Tech

Requisitos: los CSV limpios deben existir en ./outputs/
  - products_clean.csv
  - carts_clean.csv
  - users_clean.csv


Pipeline completo (DuckDB)
   - #0 Fuentes CSV → Vistas
   - #1 Validación FK + fact_ventas (modo estricto)
   - #2 Agregado por categoría (con métricas analíticas)
   - #3 Exports (gold) + vistas previas
   ================================================================ */


--  #0 FUENTES CSV  →  VISTAS

-- Limpieza
DROP VIEW  IF EXISTS v_products;
DROP VIEW  IF EXISTS v_users;
DROP VIEW  IF EXISTS v_carts;

DROP TABLE IF EXISTS stg_products;
DROP TABLE IF EXISTS stg_users;
DROP TABLE IF EXISTS stg_carts;

-- Staging físico de CSV limpios
CREATE TABLE stg_products AS
SELECT * FROM read_csv_auto('outputs/silver/products_clean.csv', HEADER=TRUE);

CREATE TABLE stg_users AS
SELECT * FROM read_csv_auto('outputs/silver/users_clean.csv', HEADER=TRUE);

CREATE TABLE stg_carts AS
SELECT * FROM read_csv_auto('outputs/silver/carts_clean.csv', HEADER=TRUE);

-- Vistas que referencian staging
CREATE VIEW v_products AS SELECT * FROM stg_products;
CREATE VIEW v_users    AS SELECT * FROM stg_users;
CREATE VIEW v_carts    AS SELECT * FROM stg_carts;

/* -- comprobación de vistas (opcional)
SELECT * FROM v_products LIMIT 3;
SELECT * FROM v_carts LIMIT 3;
SELECT * FROM v_users LIMIT 3;
*/


--   #1 VALIDACIÓN FK + CREACIÓN DE FACT_VENTAS
  

/* 1.1) Conteo rápido de faltantes de FK */
SELECT 'FK_PRODUCT_MISSING' AS check_name,
       COUNT(*) AS rows
FROM v_carts c
LEFT JOIN v_products p ON p.product_id = c.product_id
WHERE p.product_id IS NULL
UNION ALL
SELECT 'FK_USER_MISSING',
       COUNT(*)
FROM v_carts c
LEFT JOIN v_users u ON u.user_id = c.user_id
WHERE u.user_id IS NULL
;

/* 1.2) Export de filas sin FK (auditoría) */
COPY (
  SELECT c.*
  FROM v_carts c
  LEFT JOIN v_products p ON p.product_id = c.product_id
  WHERE p.product_id IS NULL
) TO 'outputs/auditoria/fk_prod_missing.csv' (HEADER, DELIMITER ',');

COPY (
  SELECT c.*
  FROM v_carts c
  LEFT JOIN v_users u ON u.user_id = c.user_id
  WHERE u.user_id IS NULL
) TO 'outputs/auditoria/fk_user_missing.csv' (HEADER, DELIMITER ',');

/* 1.3) FACT: solo filas con FK válidas (INNER JOIN) */
CREATE OR REPLACE TABLE fact_ventas AS
SELECT
    c.cart_id,
    c.user_id,
    u.nombre,
    u.apellido,
    u.email,
    u.email_valido,
    c.product_id,
    c.titulo                  AS producto_titulo,
    p.categoria,
    p.marca,
    c.cantidad,
    c.precio                  AS precio_unitario,
    c.descuento_pct,
    /* Métricas calculadas */
    ROUND(c.precio * c.cantidad, 2)                                               AS ingreso_bruto,
    ROUND((c.precio * c.cantidad) * (1 - COALESCE(c.descuento_pct,0)/100.0), 2)   AS ingreso_neto,
    ROUND((c.precio * c.cantidad)
          - ((c.precio * c.cantidad) * (1 - COALESCE(c.descuento_pct,0)/100.0)), 2) AS descuento_importe,
    /* Totales provistos por API (para auditoría) */
    c.total                   AS total_sin_descuento,
    c.total_con_descuento     AS total_con_descuento,
    /* Trazabilidad */
    CURRENT_DATE()            AS fecha_proceso
FROM v_carts c
INNER JOIN v_products p ON p.product_id = c.product_id
INNER JOIN v_users    u ON u.user_id    = c.user_id
;

/* Vista previa */
SELECT * FROM fact_ventas LIMIT 5;

/* =======================================================
   #2 AGREGADO POR CATEGORÍA (con análisis complementario)
   - lineas
   - unidades (SUM cantidad)
   - participación % sobre ingreso_neto total
   - productos_distintos (COUNT DISTINCT)
   - productos_sobre_promedio (ingreso unitario > promedio categoría)
   ======================================================= */

CREATE OR REPLACE TABLE ventas_por_categoria AS
WITH base AS (  -- métricas estándar por categoría
  SELECT
    COALESCE(categoria, 'Sin categoría') AS categoria,
    COUNT(*)                              AS lineas, 
    SUM(cantidad)                         AS unidades,
    ROUND(SUM(ingreso_bruto), 2)          AS ingreso_bruto,
    ROUND(SUM(ingreso_neto), 2)           AS ingreso_neto
  FROM fact_ventas
  GROUP BY 1
),
prod_unit AS (  -- ingreso neto unitario por producto y categoría
  SELECT
    product_id,
    categoria,
    SUM(ingreso_neto) / NULLIF(SUM(cantidad), 0) AS ingreso_unitario
  FROM fact_ventas
  GROUP BY 1,2
),
prom_cat AS (   -- promedio por categoría
  SELECT
    categoria,
    AVG(ingreso_unitario) AS avg_ingreso_unit_cat
  FROM prod_unit
  GROUP BY 1
),
flags AS (      -- conteos por categoría (con CAST para enteros)
  SELECT
    p.categoria,
    CAST(COUNT(*) AS INTEGER) AS productos_distintos,
    CAST(SUM(CASE WHEN p.ingreso_unitario > pc.avg_ingreso_unit_cat THEN 1 ELSE 0 END) AS INTEGER)
      AS productos_sobre_promedio
  FROM prod_unit p
  JOIN prom_cat pc USING (categoria)
  GROUP BY 1
),
tot AS (        -- total para participación %
  SELECT SUM(ingreso_neto) AS ingreso_total FROM base
)
SELECT
  b.categoria,
  b.lineas,
  b.unidades,
  b.ingreso_bruto,
  b.ingreso_neto,
  ROUND(b.ingreso_bruto - b.ingreso_neto, 2) AS descuento_total,
  ROUND(100.0 * b.ingreso_neto / NULLIF(t.ingreso_total, 0), 2) AS participacion_pct,
  f.productos_distintos,
  f.productos_sobre_promedio,
  ROUND(100.0 * f.productos_sobre_promedio / NULLIF(f.productos_distintos, 0), 2)
    AS pct_prod_sobre_promedio,
  CURRENT_DATE() AS fecha_proceso
FROM base b
CROSS JOIN tot t
LEFT JOIN flags f USING (categoria)
ORDER BY b.ingreso_neto DESC
;

/* Vista previa */
SELECT * FROM ventas_por_categoria LIMIT 10;

/* =======================
   #3 EXPORTS (CAPA GOLD)
   ======================= */

COPY fact_ventas           TO 'outputs/gold/fact_ventas.csv'          (HEADER, DELIMITER ',');
COPY ventas_por_categoria  TO 'outputs/gold/ventas_por_categoria.csv' (HEADER, DELIMITER ',');

/* (opcional) export de resumen de conteos FK a un único CSV */
COPY (
  SELECT 'FK_PRODUCT_MISSING' AS check_name,
         COUNT(*) AS rows
  FROM v_carts c
  LEFT JOIN v_products p ON p.product_id = c.product_id
  WHERE p.product_id IS NULL
  UNION ALL
  SELECT 'FK_USER_MISSING',
         COUNT(*)
  FROM v_carts c
  LEFT JOIN v_users u ON u.user_id = c.user_id
  WHERE u.user_id IS NULL
) TO 'outputs/auditoria/validaciones_fk.csv' (HEADER, DELIMITER ',');
