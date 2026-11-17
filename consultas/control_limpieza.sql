SELECT
    COUNT(*) AS filas,
    COUNT(DISTINCT id_pedido) AS ids_distintos,
    SUM(CASE WHEN fecha_pedido IS NULL THEN 1 ELSE 0 END) AS sin_fecha,
    SUM(CASE WHEN pais IS NULL THEN 1 ELSE 0 END) AS sin_pais,
    SUM(CASE WHEN categoria IS NULL THEN 1 ELSE 0 END) AS sin_categoria,
    SUM(CASE WHEN cantidad IS NULL OR cantidad <= 0 THEN 1 ELSE 0 END) AS cantidad_mala,
    SUM(CASE WHEN precio_unitario IS NULL OR precio_unitario <= 0 THEN 1 ELSE 0 END) AS precio_malo,
    SUM(CASE WHEN total IS NULL THEN 1 ELSE 0 END) AS sin_total,
    SUM(CASE WHEN estado NOT IN ('entregado', 'enviado', 'pendiente', 'cancelado') THEN 1 ELSE 0 END) AS estado_malo
FROM rechazados_limpios;