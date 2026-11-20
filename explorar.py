import duckdb
import pandas as pd

pd.set_option("display.width", 250)
pd.set_option("display.max_columns", 50)
pd.set_option("display.max_rows", 300)
pd.set_option("display.max_colwidth", 60)

con = duckdb.connect()
con.execute("CREATE TABLE raw AS SELECT * FROM read_csv('datos/pedidos.csv', header=true, all_varchar=true)")


def q(titulo, sql):
    print()
    print("=== " + titulo)
    print(con.execute(sql).df().to_string(index=False))


columnas = [fila[0] for fila in con.execute("DESCRIBE raw").fetchall()]
numericas = ["cantidad", "precio_unitario", "descuento_pct", "total"]

q("filas e ids", "SELECT COUNT(*) AS filas, COUNT(DISTINCT id_pedido) AS ids_distintos, COUNT(*) - COUNT(DISTINCT id_pedido) AS ids_repetidos FROM raw")
q("filas totalmente iguales", "SELECT COUNT(*) AS filas, (SELECT COUNT(*) FROM (SELECT DISTINCT * FROM raw)) AS filas_distintas FROM raw")
q("ids repetidos (ejemplos)", "SELECT id_pedido, COUNT(*) AS n FROM raw GROUP BY id_pedido HAVING COUNT(*) > 1 ORDER BY n DESC, id_pedido LIMIT 20")

partes = ["SUM(CASE WHEN {c} IS NULL OR TRIM({c}) = '' THEN 1 ELSE 0 END) AS {c}".format(c=c) for c in columnas]
q("vacios por columna", "SELECT " + ", ".join(partes) + " FROM raw")

partes = ["SUM(CASE WHEN {c} <> TRIM({c}) THEN 1 ELSE 0 END) AS {c}".format(c=c) for c in columnas]
q("textos con espacios al inicio o al final", "SELECT " + ", ".join(partes) + " FROM raw")

for c in ["pais", "categoria", "estado", "medio_pago"]:
    q("valores de " + c, f"SELECT {c}, COUNT(*) AS n FROM raw GROUP BY {c} ORDER BY n DESC")

q("ciudades por pais", "SELECT pais, ciudad, COUNT(*) AS n FROM raw GROUP BY pais, ciudad ORDER BY pais, ciudad LIMIT 150")
q("productos por categoria", "SELECT categoria, producto, COUNT(*) AS n FROM raw GROUP BY categoria, producto ORDER BY categoria, producto LIMIT 150")

q("id_pedido con formato distinto de P- y 5 digitos", "SELECT id_pedido, COUNT(*) AS n FROM raw WHERE id_pedido IS NULL OR NOT regexp_matches(id_pedido, '^P-[0-9]{5}$') GROUP BY id_pedido ORDER BY n DESC LIMIT 30")
q("id_cliente con formato distinto de C y 4 digitos", "SELECT id_cliente, COUNT(*) AS n FROM raw WHERE id_cliente IS NULL OR NOT regexp_matches(id_cliente, '^C[0-9]{4}$') GROUP BY id_cliente ORDER BY n DESC LIMIT 30")
q("emails con formato raro", "SELECT email_cliente, COUNT(*) AS n FROM raw WHERE email_cliente IS NULL OR NOT regexp_matches(email_cliente, '^[^@ ]+@[^@ ]+[.][^@ ]+$') GROUP BY email_cliente ORDER BY n DESC LIMIT 30")

q("fechas con formato distinto de AAAA-MM-DD", "SELECT fecha_pedido, COUNT(*) AS n FROM raw WHERE fecha_pedido IS NULL OR NOT regexp_matches(fecha_pedido, '^[0-9]{4}-[0-9]{2}-[0-9]{2}$') GROUP BY fecha_pedido ORDER BY n DESC LIMIT 30")
q("fechas que no se convierten a DATE", "SELECT fecha_pedido, COUNT(*) AS n FROM raw WHERE fecha_pedido IS NOT NULL AND TRY_CAST(fecha_pedido AS DATE) IS NULL GROUP BY fecha_pedido ORDER BY n DESC LIMIT 30")
q("rango de fechas validas", "SELECT MIN(TRY_CAST(fecha_pedido AS DATE)) AS minima, MAX(TRY_CAST(fecha_pedido AS DATE)) AS maxima FROM raw")

for c in numericas:
    q("valores no numericos en " + c, f"SELECT {c}, COUNT(*) AS n FROM raw WHERE {c} IS NOT NULL AND TRIM({c}) <> '' AND TRY_CAST({c} AS DOUBLE) IS NULL GROUP BY {c} ORDER BY n DESC LIMIT 30")
    q("resumen de " + c, f"SELECT COUNT(TRY_CAST({c} AS DOUBLE)) AS numericos, SUM(CASE WHEN TRY_CAST({c} AS DOUBLE) < 0 THEN 1 ELSE 0 END) AS negativos, SUM(CASE WHEN TRY_CAST({c} AS DOUBLE) = 0 THEN 1 ELSE 0 END) AS ceros, MIN(TRY_CAST({c} AS DOUBLE)) AS minimo, MAX(TRY_CAST({c} AS DOUBLE)) AS maximo FROM raw")

q("cantidad con decimales", "SELECT COUNT(*) AS n FROM raw WHERE TRY_CAST(cantidad AS DOUBLE) <> FLOOR(TRY_CAST(cantidad AS DOUBLE))")
q("descuento fuera de 0 a 100", "SELECT COUNT(*) AS n FROM raw WHERE TRY_CAST(descuento_pct AS DOUBLE) < 0 OR TRY_CAST(descuento_pct AS DOUBLE) > 100")

q("total contra el calculado", "SELECT COUNT(*) AS filas_comparadas, SUM(CASE WHEN ABS(t - c) > 0.01 THEN 1 ELSE 0 END) AS distintos, SUM(CASE WHEN ABS(t - c) > 0.01 AND ABS(t - ABS(c)) <= 0.01 THEN 1 ELSE 0 END) AS distintos_solo_por_signo FROM (SELECT TRY_CAST(total AS DOUBLE) AS t, TRY_CAST(cantidad AS DOUBLE) * TRY_CAST(precio_unitario AS DOUBLE) * (1 - TRY_CAST(descuento_pct AS DOUBLE) / 100) AS c FROM raw) WHERE t IS NOT NULL AND c IS NOT NULL")
q("ejemplos de total distinto del calculado", "SELECT id_pedido, cantidad, precio_unitario, descuento_pct, total, ROUND(TRY_CAST(cantidad AS DOUBLE) * TRY_CAST(precio_unitario AS DOUBLE) * (1 - TRY_CAST(descuento_pct AS DOUBLE) / 100), 2) AS calculado FROM raw WHERE total IS NOT NULL AND ABS(TRY_CAST(total AS DOUBLE) - TRY_CAST(cantidad AS DOUBLE) * TRY_CAST(precio_unitario AS DOUBLE) * (1 - TRY_CAST(descuento_pct AS DOUBLE) / 100)) > 0.01 LIMIT 15")