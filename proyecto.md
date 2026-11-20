# Pipeline ETL de pedidos de Valhalla S.A.

El tema es el e-commerce de Valhalla S.A. (tema_01). El pipeline toma el archivo pedidos.csv, revisa los datos, corrige lo que se puede corregir y deja una tabla final en DuckDB. Con esa tabla respondo cinco preguntas del negocio. Todo corre solo con Airflow a las 2:00 AM.

## Qué hay en el repositorio

- pedidos.csv: los datos originales, 2575 filas. No se modifico.
- pipeline.py: el script principal. Corre las etapas en orden.
- consultas/: los archivos SQL que usa el pipeline.
- dags/dag_pipeline.py: el DAG de Airflow.
- pipeline.duckdb: la base de datos que genera el pipeline.
- informe.md e informe.pdf: el informe con los resultados.
- explorar.py y exploracion.txt: lo que usé al principio para mirar los datos antes de escribir las reglas.

## Archivos de la carpeta consultas

- extract.sql: carga el CSV en la tabla raw_pedidos. Todo entra como texto para no perder nada.
- validar.sql: aplica 13 reglas de calidad. Separa los pedidos en validos y rechazados, y anota el motivo de cada rechazo.
- limpiar.sql: corrige los rechazados que se pueden recuperar.
- unir.sql: junta los válidos con los rechazados ya corregidos y arma tabla_final.
- preguntas.sql: las cinco consultas que responden las preguntas del negocio.
- control_limpieza.sql y control_final.sql: consultas que usé para comprobar que los números cierran.

## Cómo funciona

Primero se carga el CSV en raw_pedidos. Después se validan las filas con las 13 reglas. De las 2575 filas, 1475 pasaron todas las reglas y 1100 fueron rechazadas.

Después se limpian los rechazados. Se corrigen fechas, precios, cantidades, estados, países, categorías y totales. Los pedidos repetidos se dejan una sola vez. De los 1100 rechazados quedaron 1073 después de la limpieza.

Al final se unen los válidos con los rechazados corregidos. La tabla tabla_final tiene 2500 filas, una por cada id_pedido. Sobre esa tabla corren las preguntas.

Todas las tablas se crean con CREATE OR REPLACE TABLE. Por eso se puede correr el pipeline muchas veces y el resultado es siempre el mismo.

## Cómo correrlo a mano

Hace falta Python 3 con duckdb y pandas.

```
python3 -m venv venv
source venv/bin/activate
pip install duckdb pandas
python pipeline.py
```

El script muestra por pantalla la cantidad de filas de cada etapa y las respuestas a las cinco preguntas. La base queda guardada en pipeline.duckdb.

## Airflow

El DAG se llama pipeline_pedidos_valhalla y está en dags/dag_pipeline.py. Tiene cinco tareas que corren una después de la otra:

1. extraer_y_cargar
2. validar
3. limpiar
4. unir
5. responder_preguntas

Se ejecuta todos los días a las 2:00 AM, con la expresión 0 2 * * * y la zona horaria America/Argentina/Buenos_Aires.

Para probarlo:

```
pip install apache-airflow
export AIRFLOW_HOME=$HOME/airflow
export AIRFLOW__CORE__DAGS_FOLDER=$PWD/dags
export AIRFLOW__CORE__LOAD_EXAMPLES=False
airflow standalone
```

Después se entra a http://localhost:8080 y se busca el DAG. La contraseña del usuario admin aparece en la terminal cuando arranca standalone. Con el botón Trigger se puede correr a mano sin esperar a las 2:00 AM.

Lo probé con Airflow 3.3.0, DuckDB 2.0.0, pandas 2.3.3 y Python 3.13.5, en Debian sobre WSL2.

## Cosas que se decidio 

- Las fechas del archivo vienen como DD/MM/AAAA. Revisamos que todas se puedan convertir y ninguna falló.
- El enunciado no dice si los pedidos cancelados cuentan en la facturación mensual. Por eso en la pregunta 2 se coloco las dos versiones: con todos los pedidos y sin los cancelados.
- Los montos están en pesos argentinos.
- Las cantidades negativas las paamos a positivas, porque el total de esas filas ya estaba calculado con la cantidad positiva.

Los resultados completos están en el informe.