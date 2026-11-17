import duckdb
from pathlib import Path

CARPETA = Path(__file__).resolve().parent
RUTA_CSV = CARPETA / "datos" / "pedidos.csv"
RUTA_DB = CARPETA / "pipeline.duckdb"
CARPETA_SQL = CARPETA / "consultas"


def ejecutar_archivo_sql(nombre):
    texto = (CARPETA_SQL / nombre).read_text(encoding="utf-8")
    texto = texto.replace("RUTA_CSV", str(RUTA_CSV))
    con = duckdb.connect(str(RUTA_DB))
    con.execute(texto)
    con.close()


def contar_filas(tabla):
    con = duckdb.connect(str(RUTA_DB))
    filas = con.execute("SELECT COUNT(*) FROM " + tabla).fetchone()[0]
    con.close()
    return filas


def mostrar_consulta(sql):
    con = duckdb.connect(str(RUTA_DB))
    print(con.execute(sql).df().to_string(index=False))
    con.close()


def mostrar_tabla(tabla):
    mostrar_consulta("SELECT * FROM " + tabla)


def mostrar_resultado(nombre):
    mostrar_consulta((CARPETA_SQL / nombre).read_text(encoding="utf-8"))


def extraer_y_cargar():
    ejecutar_archivo_sql("extract.sql")
    print("raw_pedidos:", contar_filas("raw_pedidos"), "filas")


def validar():
    ejecutar_archivo_sql("validar.sql")
    validos = contar_filas("validos")
    rechazados = contar_filas("rechazados")
    print("validos:", validos, "filas")
    print("rechazados:", rechazados, "filas")
    print("validos + rechazados:", validos + rechazados)
    mostrar_tabla("resumen_rechazos")


def limpiar():
    ejecutar_archivo_sql("limpiar.sql")
    print("rechazados_limpios:", contar_filas("rechazados_limpios"), "filas")
    mostrar_resultado("control_limpieza.sql")


def unir():
    ejecutar_archivo_sql("unir.sql")
    print("tabla_final:", contar_filas("tabla_final"), "filas")
    mostrar_resultado("control_final.sql")
    mostrar_consulta(
        "SELECT column_name, data_type FROM information_schema.columns "
        "WHERE table_name = 'tabla_final' ORDER BY ordinal_position"
    )


def responder_preguntas():
    texto = (CARPETA_SQL / "preguntas.sql").read_text(encoding="utf-8")
    consultas = [c.strip() for c in texto.split(";") if c.strip()]
    for numero, consulta in enumerate(consultas, start=1):
        print()
        print("Pregunta", numero)
        mostrar_consulta(consulta)


if __name__ == "__main__":
    extraer_y_cargar()
    validar()
    limpiar()
    unir()
    responder_preguntas()