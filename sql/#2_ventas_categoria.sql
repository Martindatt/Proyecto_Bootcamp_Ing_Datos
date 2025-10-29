/*
AGREGADO POR CATEGORÍA

- Crea una tabla que agrega las ventas por categoría de producto.

- Resume cuantas ventas (líneas de carrito) hubo por categoría,cuántas unidades se vendieron, 
el ingreso bruto (sin descuento), el ingreso neto (con descuento), el total de descuentos aplicados 
y la participación porcentual de cada categoría en el ingreso neto total.

- Además, calcula cuántos productos distintos hay por categoría,
y cuántos de esos productos tienen un ingreso neto unitario superior al promedio de su categoría.

*/


CREATE OR REPLACE TABLE ventas_por_categoria AS
WITH base AS (  -- métricas estándar por categoría (desde fact_ventas ya validada)
  SELECT
    COALESCE(categoria, 'Sin categoría') AS categoria,
    COUNT(*)                              AS lineas,
    SUM(cantidad)                         AS unidades,
    ROUND(SUM(ingreso_bruto), 2)          AS ingreso_bruto,
    ROUND(SUM(ingreso_neto), 2)           AS ingreso_neto
  FROM fact_ventas
  GROUP BY 1
),
-- ingreso neto unitario por producto dentro de su categoría
prod_unit AS (
  SELECT
    product_id,
    categoria,
    SUM(ingreso_neto) / NULLIF(SUM(cantidad), 0) AS ingreso_unitario
  FROM fact_ventas
  GROUP BY 1,2
),
-- promedio por categoría
prom_cat AS (
  SELECT
    categoria,
    AVG(ingreso_unitario) AS avg_ingreso_unit_cat
  FROM prod_unit
  GROUP BY 1
),
-- conteos por categoría: cuántos productos superan el promedio y qué % representan
flags AS (
  SELECT
    p.categoria,
    CAST(COUNT(*) AS INTEGER) AS productos_distintos,
    CAST(SUM(CASE WHEN p.ingreso_unitario > pc.avg_ingreso_unit_cat THEN 1 ELSE 0 END) AS INTEGER)
      AS productos_sobre_promedio
  FROM prod_unit p
  JOIN prom_cat pc USING (categoria)
  GROUP BY 1
),
tot AS (  -- total neto para participación %
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
ORDER BY b.ingreso_neto DESC;

-- Vista previa
SELECT * FROM ventas_por_categoria LIMIT 10;