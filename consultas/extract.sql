-- Etapa 1 y 2: extraer el CSV original y cargarlo tal cual en raw_pedidos.
-- all_varchar = true deja todas las columnas como texto, asi no se cambia ningun valor.
-- La palabra RUTA_CSV la reemplaza pipeline.py por la ruta real del archivo.
CREATE OR REPLACE TABLE raw_pedidos AS
SELECT
    id_pedido,
    fecha_pedido,
    id_cliente,
    email_cliente,
    pais,
    ciudad,
    categoria,
    producto,
    cantidad,
    precio_unitario,
    descuento_pct,
    total,
    estado,
    medio_pago
FROM read_csv('RUTA_CSV', header = true, all_varchar = true);
