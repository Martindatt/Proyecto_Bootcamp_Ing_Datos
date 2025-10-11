/* 
TRANSFORMACIONES SQL – Semana 3 (DuckDB)
Proyecto: In-nova Tech

Requisitos: los CSV limpios deben existir en ./outputs/
   - products_clean.csv
   - carts_clean.csv
   - users_clean.csv
*/


-- 0) FUENTES: Vistas sobre CSV (rutas relativas)

CREATE OR REPLACE VIEW v_products AS
SELECT * FROM read_csv_auto('outputs/products_clean.csv', HEADER=TRUE);

CREATE OR REPLACE VIEW v_carts AS
SELECT * FROM read_csv_auto('outputs/carts_clean.csv', HEADER=TRUE);

CREATE OR REPLACE VIEW v_users AS
SELECT * FROM read_csv_auto('outputs/users_clean.csv', HEADER=TRUE);


/*
1) TABLA DE HECHOS: fact_ventas (nivel ítem de carrito)
   - Une carritos con productos y usuarios a través de LEFT JOINs
   - Calcula métricas de ingresos y descuentos
   - Incluye trazabilidad del proceso
*/

CREATE OR REPLACE TABLE fact_ventas AS
SELECT
/* campos de dimensión */
  c.cart_id,
  c.user_id,
  u.nombre,
  u.apellido,
  u.email,
  u.email_valido,
  c.product_id,
  c.titulo                 AS producto_titulo,
  p.categoria,
  p.marca,
  /* Medidas a utilizar */
  c.cantidad,
  c.precio                 AS precio_unitario,
  c.descuento_pct,
/* Métricas calculadas*/
  ROUND(c.precio * c.cantidad, 2)                                             AS ingreso_bruto,
  ROUND((c.precio * c.cantidad) * (1 - COALESCE(c.descuento_pct,0)/100.0), 2) AS ingreso_neto,
  ROUND( (c.precio * c.cantidad) - ((c.precio * c.cantidad) * (1 - COALESCE(c.descuento_pct,0)/100.0)), 2) AS descuento_importe,
/* Totales para comparación o auditoría */
  c.total                 AS total_sin_descuento,
  c.total_con_descuento   AS total_con_descuento,
/* Trazabilidad de fecha */
  CURRENT_DATE()          AS fecha_proceso
FROM v_carts c
LEFT JOIN v_products p ON p.product_id = c.product_id
LEFT JOIN v_users    u ON u.user_id    = c.user_id
;

/* 
   2) AGREGADO: ventas_por_categoria
   - Resumen de líneas, unidades e ingresos por categoría
*/
CREATE OR REPLACE TABLE ventas_por_categoria AS
SELECT
  COALESCE(p.categoria, 'Sin categoría')                 AS categoria,
  COUNT(*)                                               AS lineas,
  SUM(c.cantidad)                                        AS unidades,
  ROUND(SUM(c.precio * c.cantidad), 2)                   AS ingreso_bruto,
  ROUND(SUM((c.precio * c.cantidad) * (1 - COALESCE(c.descuento_pct,0)/100.0)), 2) AS ingreso_neto,
  ROUND(ingreso_bruto - ingreso_neto, 2)                 AS descuento_total,
  CURRENT_DATE()                                         AS fecha_proceso
FROM v_carts c
LEFT JOIN v_products p ON p.product_id = c.product_id
GROUP BY 1
ORDER BY ingreso_neto DESC
;


/*
   3) EXPORT: CSVs de salida en ./outputs/
   (Dejá estas líneas activas si querés generar los archivos al correr)
*/
COPY fact_ventas           TO 'outputs/fact_ventas.csv'           (HEADER, DELIMITER ',');
COPY ventas_por_categoria  TO 'outputs/ventas_por_categoria.csv'  (HEADER, DELIMITER ',');
