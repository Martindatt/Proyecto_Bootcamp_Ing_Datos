/*
TRANSFORMACIONES SQL (SEMANA #3)
*/

-- Crear las Vistas necesarias para las transformaciones

CREATE or replace VIEW v_products AS
SELECT * FROM read_csv_auto('outputs/products_clean.csv', HEADER=TRUE);

CREATE or replace VIEW v_carts AS
SELECT * FROM read_csv_auto('outputs/carts_clean.csv', HEADER=TRUE);

CREATE or replace VIEW v_users AS
SELECT * FROM read_csv_auto('outputs/users_clean.csv', HEADER=TRUE);

-- Test: Consultar las vistas creadas
SELECT * FROM v_products LIMIT 5;
SELECT * FROM v_carts LIMIT 5;
SELECT * FROM v_users LIMIT 5;