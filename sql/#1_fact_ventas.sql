/*
TABLA DE HECHOS - FACT_VENTAS

Une los carritos (v_carts) con los productos (v_products)
y los usuarios (v_users), para construir una tabla de hechos
a nivel ítem de carrito.

*/

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
    c.total                 AS total_sin_descuento,
        ROUND((c.precio * c.cantidad) - ((c.precio * c.cantidad) * (1 - COALESCE(c.descuento_pct,0)/100.0)), 2) AS descuento_importe,
        
    c.total_con_descuento   AS total_con_descuento,
    CURRENT_DATE() AS fecha_de_venta

    FROM v_carts c
        LEFT JOIN v_products p ON p.product_id = c.product_id
        LEFT JOIN v_users    u ON u.user_id    = c.user_id
;

-- Vista previa para validar
SELECT * FROM fact_ventas LIMIT 5;