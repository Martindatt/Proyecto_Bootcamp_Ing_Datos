/*
TABLA DE HECHOS - FACT_VENTAS

Une los carritos (v_carts) con los productos (v_products)
y los usuarios (v_users), para construir una tabla de hechos
a nivel ítem de carrito.

*/

/*

Requisitos previos:

- Valida FKs y exporta auditorías
- Crea fact_ventas solo con filas válidas
*/

/* 1) Reporte rápido (conteos) */
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

/* 1.1) Exports de auditoría (usar subselect porque los CTE no persisten) */
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

/* 2) Crear la tabla de hechos con filas válidas (INNER JOIN = FK ok) */
CREATE OR REPLACE TABLE fact_ventas AS
SELECT
    c.cart_id,
    c.user_id,
    u.nombre,
    u.apellido,
    u.email,
    u.email_valido,
    c.product_id,
    c.titulo                AS producto_titulo,
    p.categoria,
    p.marca,
    c.cantidad,
    c.precio                AS precio_unitario,
    c.descuento_pct,
    -- Métricas calculadas
    ROUND(c.precio * c.cantidad, 2)                                             AS ingreso_bruto,
    ROUND((c.precio * c.cantidad) * (1 - COALESCE(c.descuento_pct,0)/100.0), 2) AS ingreso_neto,
    ROUND((c.precio * c.cantidad) - ((c.precio * c.cantidad) * (1 - COALESCE(c.descuento_pct,0)/100.0)), 2) AS descuento_importe,
    -- Totales de API (auditoría)
    c.total               AS total_sin_descuento,
    c.total_con_descuento AS total_con_descuento,
    -- Trazabilidad
    CURRENT_DATE()        AS fecha_proceso
FROM v_carts c
INNER JOIN v_products p ON p.product_id = c.product_id
INNER JOIN v_users    u ON u.user_id    = c.user_id
;

/* 3) Vista previa */
SELECT * FROM fact_ventas LIMIT 5;

