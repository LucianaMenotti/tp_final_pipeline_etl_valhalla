CREATE OR REPLACE TABLE raw_pedidos AS
SELECT *
FROM read_csv('RUTA_CSV', header = true, all_varchar = true);