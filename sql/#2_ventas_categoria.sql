/*
AGREGADO POR CATEGORÍA

Crea una tabla que agrega las ventas por categoría de producto.
Resume cuantas ventas (líneas de carrito) hubo por categoría,
cuántas unidades se vendieron, el ingreso bruto (sin descuento)
y el ingreso neto (con descuento).
*/

CREATE OR REPLACE TABLE ventas_por_categoria AS
SELECT
    COALESCE(p.categoria, 'Sin categoría')                AS categoria,
    COUNT(*)                                              AS lineas,
    ROUND(SUM(c.cantidad),0)                               AS unidades,
    ROUND(SUM(c.precio * c.cantidad), 2)                  AS ingreso_bruto,
    ROUND(SUM((c.precio * c.cantidad) * (1 - COALESCE(c.descuento_pct,0)/100.0)), 2) AS ingreso_neto,
    ROUND(ingreso_bruto - ingreso_neto, 2)                AS descuento_total,
    CURRENT_DATE()                                        AS fecha_proceso
FROM v_carts c
LEFT JOIN v_products p ON p.product_id = c.product_id
GROUP BY 1
ORDER BY ingreso_neto DESC;

-- Vista previa
SELECT * FROM ventas_por_categoria LIMIT 10;