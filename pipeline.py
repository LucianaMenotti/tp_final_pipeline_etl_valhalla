import duckdb
from pathlib import Path

# Las rutas se calculan a partir de la ubicacion de este archivo.
# Asi el proyecto funciona en cualquier carpeta, sin escribir rutas fijas.
CARPETA_PROYECTO = Path(__file__).resolve().parent
RUTA_CSV = CARPETA_PROYECTO / "datos" / "pedidos.csv"
RUTA_BASE_DE_DATOS = CARPETA_PROYECTO / "pipeline.duckdb"
CARPETA_CONSULTAS = CARPETA_PROYECTO / "consultas"

# Funciones de apoyo


def leer_archivo_sql(nombre_archivo):
    # Lee el texto de un archivo .sql de la carpeta consultas
    ruta_archivo = CARPETA_CONSULTAS / nombre_archivo
    texto_sql = ruta_archivo.read_text(encoding="utf-8")
    return texto_sql


def ejecutar_archivo_sql(nombre_archivo):
    # Ejecuta todas las consultas de un archivo .sql sobre pipeline.duckdb
    texto_sql = leer_archivo_sql(nombre_archivo)
    # Se reemplaza la palabra RUTA_CSV por la ruta real del CSV
    texto_sql = texto_sql.replace("RUTA_CSV", RUTA_CSV.as_posix())
    conexion = duckdb.connect(str(RUTA_BASE_DE_DATOS))
    conexion.execute(texto_sql)
    conexion.close()


def obtener_un_numero(consulta_sql):
    # Ejecuta una consulta que devuelve un solo numero y lo devuelve
    conexion = duckdb.connect(str(RUTA_BASE_DE_DATOS))
    resultado = conexion.execute(consulta_sql).fetchone()
    conexion.close()
    return resultado[0]


def contar_filas(nombre_tabla):
    # Cuenta las filas de una tabla
    consulta_sql = "SELECT COUNT(*) FROM " + nombre_tabla
    return obtener_un_numero(consulta_sql)


def mostrar_consulta(consulta_sql):
    # Ejecuta una consulta y muestra el resultado como tabla en pantalla
    conexion = duckdb.connect(str(RUTA_BASE_DE_DATOS))
    tabla_resultado = conexion.execute(consulta_sql).df()
    conexion.close()
    print(tabla_resultado.to_string(index=False))


def contar_filas_del_csv():
    # Cuenta las lineas del CSV original (sin contar el encabezado)
    cantidad_de_lineas = 0
    archivo = open(RUTA_CSV, "r", encoding="utf-8")
    for linea in archivo:
        cantidad_de_lineas = cantidad_de_lineas + 1
    archivo.close()
    return cantidad_de_lineas - 1



# Etapas del pipeline


def extraer_y_cargar():
    #  1 y 2: leer el CSV y cargarlo en raw_pedidos
    ejecutar_archivo_sql("extract.sql")

    filas_del_csv = contar_filas_del_csv()
    filas_en_raw = contar_filas("raw_pedidos")
    print("filas del CSV:", filas_del_csv)
    print("filas en raw_pedidos:", filas_en_raw)

    # Si no coinciden, se perdieron filas al cargar
    if filas_del_csv != filas_en_raw:
        raise ValueError("raw_pedidos no tiene la misma cantidad de filas que el CSV")


def validar():
    # 3: separar los registros en validos y rechazados
    ejecutar_archivo_sql("validar.sql")

    filas_en_raw = contar_filas("raw_pedidos")
    filas_validas = contar_filas("validos")
    filas_rechazadas = contar_filas("rechazados")
    print("raw_pedidos:", filas_en_raw)
    print("validos:", filas_validas)
    print("rechazados:", filas_rechazadas)

    # Cada registro tiene que estar en validos o en rechazados, nunca en los dos
    if filas_validas + filas_rechazadas != filas_en_raw:
        raise ValueError("validos + rechazados no suman las filas de raw_pedidos")

    print()
    print("Registros rechazados por cada regla:")
    mostrar_consulta("SELECT regla, cantidad FROM resumen_rechazos ORDER BY cantidad DESC, regla")


def limpiar():
    # 4: limpiar los rechazados y guardarlos en rechazados_limpios
    ejecutar_archivo_sql("limpiar.sql")

    filas_rechazadas = contar_filas("rechazados")
    filas_limpias = contar_filas("rechazados_limpios")
    print("rechazados:", filas_rechazadas)
    print("rechazados_limpios:", filas_limpias)

    print()
    print("Control de rechazados_limpios:")
    mostrar_consulta(leer_archivo_sql("control_limpieza.sql"))


def unir():
    # 5: unir validos y rechazados_limpios en tabla_final
    ejecutar_archivo_sql("unir.sql")

    filas_finales = contar_filas("tabla_final")
    ids_distintos = obtener_un_numero("SELECT COUNT(DISTINCT id_pedido) FROM tabla_final")
    ids_en_raw = obtener_un_numero("SELECT COUNT(DISTINCT id_pedido) FROM raw_pedidos")
    print("tabla_final:", filas_finales)
    print("ids distintos en tabla_final:", ids_distintos)
    print("ids distintos en raw_pedidos:", ids_en_raw)

    # No puede haber ids repetidos
    if filas_finales != ids_distintos:
        raise ValueError("tabla_final tiene ids repetidos")

    # Cada id del CSV original tiene que estar una vez en tabla_final
    if filas_finales != ids_en_raw:
        raise ValueError("tabla_final no tiene la misma cantidad de ids que raw_pedidos")

    print()
    print("Control de tabla_final:")
    mostrar_consulta(leer_archivo_sql("control_final.sql"))

    print()
    print("Tipos de dato de tabla_final:")
    consulta_tipos = (
        "SELECT column_name, data_type FROM information_schema.columns "
        "WHERE table_name = 'tabla_final' ORDER BY ordinal_position"
    )
    mostrar_consulta(consulta_tipos)


def responder_preguntas():
    # 6: ejecutar cada consulta de preguntas.sql y mostrar su resultado
    texto_sql = leer_archivo_sql("preguntas.sql")
    lista_de_consultas = texto_sql.split(";")

    for consulta in lista_de_consultas:
        consulta = consulta.strip()
        # El ultimo pedazo queda vacio porque el archivo termina en ;
        if consulta != "":
            lineas_de_la_consulta = consulta.split("\n")
            print()
            # La primera linea de cada consulta es un comentario con el nombre de la pregunta
            print(lineas_de_la_consulta[0])
            mostrar_consulta(consulta)


def ejecutar_pipeline_completo():
    extraer_y_cargar()
    print()
    validar()
    print()
    limpiar()
    print()
    unir()
    responder_preguntas()


if __name__ == "__main__":
    ejecutar_pipeline_completo()
