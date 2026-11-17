SELECT
    COUNT(*) AS filas,
    COUNT(DISTINCT id_pedido) AS ids_distintos,
    SUM(CASE WHEN fecha_pedido IS NULL OR pais IS NULL OR categoria IS NULL OR total IS NULL THEN 1 ELSE 0 END) AS con_nulos,
    SUM(CASE WHEN ABS(total - cantidad * precio_unitario * (1 - descuento_pct / 100)) > 0.01 THEN 1 ELSE 0 END) AS total_inconsistente,
    MIN(fecha_pedido) AS fecha_minima,
    MAX(fecha_pedido) AS fecha_maxima
FROM tabla_final;