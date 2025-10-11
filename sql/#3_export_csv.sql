-- Export de tablas a outputs
COPY fact_ventas           TO 'outputs/fact_ventas.csv'           (HEADER, DELIMITER ',');
COPY ventas_por_categoria  TO 'outputs/ventas_por_categoria.csv'  (HEADER, DELIMITER ',');
