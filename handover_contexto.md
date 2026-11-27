# Handover de contexto v3: proyecto, cambios de enfoque y material para la redacción de la tesis

Reemplaza a `handover_contexto_v2.md`. El detalle técnico (rutas, variables, experimentos, resultados, reglas de decisión y punto de retoma) está en `Handover_Modelamiento_Panel_Final.md`. Léelos juntos. Fecha: 27 de noviembre de 2026. Próximo hito del usuario con su asesor: 11 de diciembre de 2026.

---

## 1. Qué es este proyecto

Tesis de la Maestría en Analítica de Negocios (Universidad del Rosario). El producto es un modelo predictivo de la deserción escolar por sede educativa oficial en Colombia y una herramienta para usuarios no técnicos de las Secretarías de Educación que sirva como alerta temprana y explique qué factores empujan el riesgo de cada sede. La herramienta muestra el scoring y tiene además un laboratorio donde se pueden subir datos (solo puntúa, no reentrena).

**Enfoque actual (después de la reunión con el asesor).** Clasificación multiclase con **dos variables objetivo**: el **nivel** de deserción de la sede en el año objetivo (hasta cuatro clases, con el cero como clase aparte y cortes por percentil estáticos) y la **variación** respecto de la última tasa conocida (baja, igual o sube). La combinación de ambas orienta la prioridad (por ejemplo, nivel alto y tendencia creciente = prioridad máxima). Modelos básicos: Random Forest, XGBoost y regresión multinomial; después, un stacking. La explicabilidad se hace a través de los modelos principales (los multinomiales son aditivos) y no del ensamble final.

---

## 2. Cómo ha cambiado el enfoque (para el texto y para no repetir debates)

| Etapa | Qué se planteaba | Por qué cambió |
|---|---|---|
| Planteamiento original | Ensamble de clasificación del riesgo, con target municipal imputado a la sede | Se halló deserción a nivel sede en los archivos `Sit_Acad` del C-600; el target municipal era un solo valor por municipio y año |
| Tras construir el panel sede-año | Regresión de la tasa solo en sedes con tasa positiva (ensamble de regresores con SHAP) | El experimento de tamaño mostró que "solo positivas" sobrestima 25 a 40% en el panel sin ICFES y queda dominado en desviación |
| Tras los experimentos 2 a 6 | Regresión Poisson ponderada por estudiantes sobre todas las sedes con registro, ensamble por votación, SHAP, prioridad = tasa esperada × estudiantes^alpha | Mejor desviación y calibración; la prioridad evita ignorar sedes pequeñas |
| **Reunión con el asesor (actual)** | **Clasificación multiclase de nivel y de variación, con cortes estáticos, rezagos de hasta 3 años y stacking** | El asesor consideró que la base anual (2017 a 2024) no basta para un modelo de series de tiempo robusto (predecir el siguiente dato equivale a un promedio móvil) y que los rangos son más legibles para decidir política |

Lo aprendido en la etapa Poisson **se conserva como evidencia** (la historia de la sede es un predictor débil, las sedes pequeñas meten ruido, el nivel de la tasa se mueve de año a año) y como material de la tesis. Detalle en el handover técnico, secciones 9 y 11.

---

## 3. Objetivos de la tesis (texto original) y qué debe reflejar

**Objetivo general (original).** Desarrollar un modelo en ensamble para clasificar el riesgo de deserción a nivel de sede educativa pública, a partir de datos abiertos con lag de dos años. Debe derivar en una herramienta para usuarios no técnicos que permita identificar alertas tempranas en las Secretarías de Educación, junto con una explicación de qué variables contribuyen a la deserción, para priorizar tipos de intervención de retención antes de que ocurra el abandono y formular estrategias de mayor impacto.

**Objetivos específicos (original).**
1. Construir los paneles longitudinales maestros de sedes educativas oficiales para 2018 a 2024, integrando y depurando variables de distintas fuentes abiertas.
2. Identificar y construir las variables predictoras del riesgo, agrupadas en familias que correspondan a su tratamiento óptimo para evitar la deserción.
3. Construir un modelo ensamblado por voting que corra con granularidad de sede, evalúe de forma constante cuál es el modelo adecuado para los distintos casos posibles y elija el de mejor desempeño frente al objetivo general.
4. Aplicar técnicas de explainability (SHAP) para identificar el peso de cada variable y de nodos específicos en la decisión final, de modo que se pueda explicar a los tomadores de decisión qué hace vulnerable a cada sede y formular estrategias específicas.
5. Crear un instrumento para usuarios no técnicos de las Secretarías que permita acceder al modelo y entender la necesidad puntual de cada sede de forma simple e intuitiva, con el propósito de proponer recomendaciones de política que ataquen la variable de mayor peso en cada caso.

**Cambios que el texto debe reflejar (propuestas de redacción; validar con el asesor).**
- "Clasificar el riesgo" **vuelve a ser clasificación**, pero ahora **del nivel de deserción esperado y de su variación** (hasta cuatro clases de nivel y tres de variación), no de un nivel de riesgo derivado de un puntaje.
- "Lag de dos años" pasa a "rezago de dos a tres años según la fuente": las covariables llegan con dos años de rezago y la deserción propia de la sede con tres, porque el archivo de situación académica se publica con más demora. La ventana de historia de la deserción usa los rezagos de tres, cuatro y cinco años.
- Objetivo 1: el panel cubre de 2017 a 2024 (no hay datos de 2025: el DANE suspendió y reprogramó esa recolección). Confirmar con el usuario la redacción de por qué el panel empieza en 2017.
- Objetivo 3: el modelo es un ensamble (stacking, no solo voting) de Random Forest, XGBoost y regresiones multinomiales; la regresión Poisson se reevalúa. La comparación incluye modelo global, global con tipología y modelos por segmento si los números lo justifican.
- Objetivo 4: la explicabilidad se hace con SHAP sobre el modelo de árboles y con los coeficientes del multinomial (aditivo), **por familias de variables y sin la historia propia**; no sobre el ensamble final.
- Objetivo 5: la herramienta muestra el nivel esperado, la dirección esperada (sube o baja) y los factores principales por familia; incluye un laboratorio para subir datos. Reformular "atacar la variable de mayor peso" como "explicar por familias de factores", porque la historia propia concentra buena parte del peso y no es una palanca de política (a validar con el asesor).

---

## 4. Contexto y problema (hechos con fuente; no inventar cifras)

- El sistema de educación básica y media atiende cerca de 9,8 millones de estudiantes, con arquitectura descentralizada: el MEN define política, datos y recursos; las Secretarías de Educación departamentales y municipales certificadas la ejecutan (97 Secretarías certificadas). Según el LEE (2024), el 80% asiste a colegios públicos en contextos urbanos, rurales y de difícil acceso.
- Crisis de permanencia: en 2022 y 2023 más de 709.000 estudiantes abandonaron el colegio. Según SINEB, citado por El Tiempo (2025a), la deserción fue de 4,1% en 2022 y 3,7% en 2023 (335.364 menores ese último año). Departamentos como Putumayo, Guainía y Arauca alcanzan 8,11%.
- Las herramientas vigentes (SIMAT y SIMPADE) producen estadísticas descriptivas anuales, sin características que permitan analizar causas, y se publican con hasta dos años de demora. Detectan la deserción cuando el estudiante ya dejó de matricularse.
- La decisión bajo análisis es la asignación anual de recursos de retención por parte de las Secretarías (PAE, atención psicosocial, transporte escolar, flexibilización curricular), hoy tomada con información rezagada y sin capacidad predictiva.
- Costo económico citado: 2,8 billones de pesos anuales perdidos por abandono escolar (LEE, 2024).
- Justificación: según el informe del LEE de la Javeriana et al. (2026), "Las implicaciones de la inacción en la educación media en Colombia", solo 13 de cada 100 estudiantes que ingresan terminan la media a tiempo con las competencias básicas. Un joven con media completa puede ganar hasta 28% más que quien solo terminó primaria, y cada año adicional de escolaridad aumenta el ingreso promedio en 10,1%. El argumento central es que la deserción es una trampa de pobreza de ciclo largo que se puede anticipar con datos que el Estado ya posee pero no explota.
- Actores: MEN (rector de política y datos), Secretarías de Educación (usuarias directas del sistema de alerta), rectores y docentes (generan las señales que alimentan el SIMAT).

---

## 5. Fuentes de datos (todas públicas)

- **Formulario C-600 del DANE** (microdatos de educación formal): matrícula, composición del alumnado (desplazados, limitación, etnia, modelos tradicionales y flexibles) y la **situación académica** (`Sit_Acad`, de donde sale el target: desertores sobre estudiantes por sede). Cada archivo `Sit_Acad` describe el año anterior a su etiqueta.
- **SIMAT** (tasas de deserción y repitencia municipales, año del evento) y **DIVIPOLA**. Quedan como contexto en el maestro; no entran al modelo base.
- **ICFES / Saber 11** por sede (solo las sedes que ofrecen grado 11 tienen estas variables).
- **IPM** (privaciones por región y año): en el maestro, excluido del modelo por deriva.
- **PDET y ZOMAC** (banderas municipales).
- **Categoría de ruralidad del DNP** (`Clasificacion_Ruralidad_DNP.xlsx`): cuatro categorías (Ciudades y aglomeraciones, Intermedio, Rural, Rural disperso). El usuario hablaba de tres tipologías; hay cuatro. La metodología de esta clasificación no se ha revisado.
- Los atributos municipales de las sedes salen del código de sede (`SEDE_CODIGO[1:6]`), con resolución de casos especiales mediante ICFES y SINEB, y `REGION_DANE` nunca se inventa.

---

## 6. Enfoque metodológico actual (frente al previsto)

1. Panel longitudinal por sede y año, de 2017 a 2024, dividido en dos paneles: sedes con ICFES (`ofrecen11`) y sin ICFES (`Solo_Primaria`).
2. Predictores en familias (historia de deserción, tamaño y dinámica de matrícula, composición del alumnado, contexto territorial y ICFES cuando existe), medidos con el desfase que tendrían al momento de predecir.
3. Variable objetivo A: **nivel** (cero observado aparte; tres rangos de la tasa ajustada por empirical Bayes con cortes por percentil estáticos de todas las sedes y años disponibles). Variable objetivo B: **variación** frente a la tasa de hace tres años, con un umbral estadístico (límite de embudo) a calibrar.
4. Rezagos de la deserción de la sede a tres, cuatro y cinco años (tasa observada, tasa ajustada y conteos), con imputación para los modelos que no manejan faltantes.
5. Clasificadores base (XGBoost, Random Forest, multinomial) con pesos balanceados por clase, comparados contra la persistencia (la clase de hace tres años) y contra un modelo de solo historia; métricas F, kappa cuadrático, AUC multiclase, ponderadas por estudiantes y por estrato de tamaño; retrocesos temporales e intervalos por bootstrap de municipios.
6. Stacking posterior; explicabilidad por familias sin la historia propia.
7. Herramienta con scoring descargable y laboratorio de carga de datos.

---

## 7. Tensiones del texto actual

| Tema | Estado |
|---|---|
| Horizonte: "lag de dos años" frente a "antes del cierre del año lectivo" | Resuelto en el diseño: covariables en t-2 y deserción propia en t-3. El texto debe decirlo con precisión y retirar o matizar "antes del cierre del año lectivo" |
| C-600 desde 2014 y panel 2018 a 2024 | Cambió: el panel va de 2017 a 2024. Falta justificar el recorte |
| Cifras de 8,11% por departamento y 4,1% y 3,7% (fuentes distintas) | Abierto: verificar definiciones y comparabilidad antes de presentarlas juntas |
| "Las Secretarías ahorrarán billones" | Abierto: proyección sin sustento cuantitativo; matizar o respaldar |
| Resumen ejecutivo repite el párrafo sobre la estructura del sistema educativo | Abierto: depurar |
| Mezcla de SIMAT, SIMPADE y SINEB | Abierto: el target sale de la situación académica del C-600, no del SIMAT; aclarar el rol de cada sistema |
| Tres tipologías frente a cuatro categorías de ruralidad | Abierto: confirmar con el asesor |
| Formulaciones de "sin riesgo" | La herramienta dice "sin deserción observada" (descriptivo, basado en la historia propia); no significa ausencia de riesgo |
| Regresión Poisson en el texto | **Nuevo:** si el documento aún la presenta como modelo final, reformular como exploración previa que sustenta decisiones (historia débil, ruido de sedes pequeñas) y que motivó el paso a clasificación |
| "Variable de mayor peso en cada caso" (objetivo 5) | **Nuevo:** reformular por familias (la historia propia no es accionable) |
| Pocos años para modelar (cuatro años objetivo, tres retrocesos) | **Nuevo:** declararlo como limitación; es el argumento del asesor para abandonar la regresión de series de tiempo |

---

## 8. Estilo de redacción e instrucciones para el Claude (o agente) que reciba esto

- **Textos de tesis:** español formal, tercera persona, prosa natural, sin guiones largos y sin exceso de subtítulos.
- **Con el usuario:** español, respuestas directas y estructuradas, una pregunta como máximo por respuesta. Para los experimentos: explicación **como a un niño de cinco años** (qué queremos ver, qué se hizo, para qué, conclusión) y, al cierre de **cada** experimento, un **párrafo académico** aparte (formato y ejemplos en la sección 10 de este documento). Los mensajes para el asesor, tipo WhatsApp y concisos.
- **Código:** completo y listo para pegar, **como celda nueva del notebook `5_COD_Pre_Model.ipynb`** (no ofrecer `.py` aparte), con comentarios en inglés, orden rutas, variables generales, funciones y ejecución al final; nombres exactos de columnas. **Sin CSV** salvo necesidad.
- No inventar cifras ni referencias. Usar solo las citadas en la sección 4 o pedir la fuente. La bibliografía de la sección 12 tiene su grado de verificación.
- No afirmar que el código funciona con los datos reales: nunca se corrió con ellos. Decir qué se probó con datos sintéticos y que el usuario corre las celdas y pega los `.md`.
- Señalar al usuario las tensiones de la sección 7 cuando sean relevantes.
- Estado de la conversación: el punto de retoma está en la sección 0 del handover técnico. **El premodelamiento está cerrado (experimentos 1 a 8 analizados). La sesión de modelamiento arranca con el experimento 9 (modelos base: XGBoost, Random Forest y Multinomial).**
- El usuario pegará además gráficos de la tesis y espera que se interpreten a la luz del objetivo del proyecto.

---

## 9. Glosario (términos y cómo usarlos)

| Término | Definición breve para el texto |
|---|---|
| Sede educativa | Establecimiento o sede oficial identificada con un código de 12 dígitos |
| Panel longitudinal | Una fila por sede y año |
| Año objetivo (t) | Año cuya deserción se predice |
| Año de referencia | Año en que se miden los predictores (t-2 las covariables; t-3, t-4 y t-5 la deserción propia) |
| Tasa de deserción de la sede | Desertores divididos entre estudiantes reportados en la situación académica |
| Ceros imputados | Sedes sin registro de situación académica en un año con archivo, a las que se asigna tasa 0 por decisión metodológica; se marcan con bandera |
| Cero observado | Sede con registro y cero desertores; es la clase aparte "sin deserción observada" |
| Peso o exposición | Número de estudiantes de la sede en el año objetivo; no es predictor |
| Tasa ajustada | Tasa corregida por tamaño: (desertores + K × media) / (estudiantes + K) |
| K (contracción) | Número de estudiantes imaginarios, con la media general, que se suman para no creerle demasiado a sedes pequeñas |
| Clase de nivel | Cero observado, o bajo, medio o alto según cortes por percentil de la tasa ajustada, fijos entre años |
| Clase de variación | Baja, igual o sube respecto de la tasa de hace tres años, según un umbral estadístico |
| Límite de embudo | Umbral para decidir si un cambio supera el ruido binomial esperado, en múltiplos (z) del error estándar de la diferencia |
| Persistencia | Usar la clase de hace tres años como predicción de la clase actual; es la línea base |
| Modelo de solo historia (`HIST`) | Clasificador con una sola variable, la tasa ajustada de hace tres años; mide cuánto agregan las demás variables |
| Kappa cuadrático ponderado | Acuerdo entre clase real y predicha corregido por azar, penalizando más los errores lejanos en clases ordenadas |
| Macro-F1 | Promedio del F1 de cada clase, sin ponderar por tamaño de clase |
| AUC uno contra el resto | Área bajo la curva ROC de cada clase contra las demás, promediada |
| Regresión a la media | Las sedes con valores extremos tienden a acercarse al promedio, en parte por azar |
| Estrato de tamaño (Q1 a Q5) | Quintiles de la matrícula total; Q1 son las sedes más pequeñas |
| Retroceso temporal | Entrenar con los años objetivo anteriores y evaluar en el siguiente |
| Bootstrap por municipio | Remuestreo de municipios completos para estimar la incertidumbre respetando que las sedes de un municipio se parecen |
| Familia de variables | Agrupación de predictores para explicar: historia, tamaño y dinámica, composición, contexto territorial, ICFES |
| Segmento | Combinación de ICFES (sí o no) y categoría de ruralidad del DNP |
| PSI / SMD | Índice de estabilidad de la población y diferencia media estandarizada |
| Alpha, prioridad = tasa × n^alpha | Resultado de la etapa Poisson; ya no es la regla principal de prioridad |

---
## 10. Material para la redacción de la tesis

### 10.1 Formato del párrafo académico que se entrega al cierre de cada experimento
Un solo párrafo, español formal, tercera persona, prosa continua, cifras concretas con intervalos cuando existan, **criterio de decisión explícito** y sin guiones largos. Ejemplo que dio el usuario (de su tesis, sobre alpha): "El compromiso se observa con claridad pues a medida que α baja, la captura total cae y la captura Q1 sube como se mencionó antes del análisis. Ahora bien, el criterio para fijar α es el mayor valor con el que las sedes pequeñas reciben al menos lo que daría una lista al azar, es decir, una captura Q1 de 10% [...]. Sobre esta lógica con α = 0.20 el criterio se cumple en los dos paneles, con una captura Q1 de 15.2% en el panel con grado 11 y de 18.0% en el de solo primaria, es decir, 1.5 y 1.8 veces el azar [...]".

### 10.2 Bloques de redacción (borradores; adaptar y validar con el asesor)

**Unidad de análisis y variable objetivo base.** La unidad de análisis es la sede educativa oficial en un año. La tasa de deserción de la sede se calcula como el número de estudiantes desertores sobre el total de estudiantes reportados en la situación académica del año, a partir del formulario C-600. Cada archivo de situación académica describe el año anterior al de su etiqueta, por lo que cada uno se almacenó bajo el año que realmente describe. Con esto la variable varía entre sedes del mismo municipio, algo que no ocurría con la tasa municipal del SIMAT, que se conserva solo como contexto.

**Horizontes de información.** Cada variable se mide con el desfase con el que estaría disponible al momento de predecir. Las covariables del C-600, del ICFES y de las fuentes territoriales se toman con dos años de rezago, mientras que la deserción propia de la sede se toma con tres, porque el archivo de situación académica se publica con mayor demora. La historia de la sede se resume con los rezagos de tres, cuatro y cinco años. Todos los rezagos se calculan por año calendario y no por posición de fila, de modo que las sedes con años faltantes no reciben información de un año equivocado.

**Sedes sin registro.** En los años para los que existe el archivo de situación académica, las sedes que no aparecen se tratan como sedes sin deserción y reciben una tasa de cero, marcada con una bandera para poder excluirlas en análisis de sensibilidad. Esta decisión incide poco en el panel con ICFES y más en el panel sin ICFES. En los experimentos de modelamiento estas observaciones no entran porque su denominador es desconocido.

**Segmentación por ICFES y ruralidad.** Las sedes se dividen en dos paneles según tengan o no resultados del ICFES, porque las variables disponibles son distintas. A esa división se añade la categoría de ruralidad del DNP por municipio, que se usa para definir segmentos y para comparar un modelo global con modelos por segmento.

**Depuración de predictores.** El conjunto de predictores se depuró con criterios de colinealidad (factor de inflación de la varianza y correlación de Spearman) y de estabilidad entre los años de entrenamiento y de prueba (PSI y SMD). Se eliminaron las cinco puntuaciones por área del ICFES, redundantes con el puntaje global (VIF de 8,6 a 17,4 y correlaciones entre 0,86 y 0,95); las variables de pobreza multidimensional por región y año, con una deriva extrema (PSI superior a 4); y las tasas municipales rezagadas, con deriva alta. El conjunto final no presenta alertas: el VIF máximo es 2,27, el PSI máximo 0,033 y la correlación de Spearman máxima 0,68.

**El problema del tamaño de la sede.** Cuando se calcula una tasa con pocos estudiantes, un solo desertor produce una tasa alta. En el panel sin ICFES, el 41,6% de las sedes más pequeñas quedaba en el nivel más alto de riesgo frente al 0,13% de las más grandes cuando se usaba la tasa sin ajuste. Se incorporó un ajuste de contracción hacia la media y se estimó, con el método de momentos de un modelo Beta-Binomial, la fuerza del ajuste que sugieren los datos (cerca de 10 estudiantes imaginarios en el panel sin ICFES y de 16 en el panel con grado 11). El mismo problema aparece al definir rangos: con la tasa observada, la clase más alta se concentra en sedes pequeñas, y con la tasa ajustada se reparte entre los tamaños.

**La historia como filtro.** Se evaluó si la ausencia de deserción en la historia de una sede permite excluirla de la predicción. Aunque la historia es un buen predictor, la regla deja dentro de su grupo a más de la mitad de las sedes de zonas rurales con deserción positiva en el panel sin ICFES y a una proporción cercana a dos tercios de las sedes del nivel más alto. Por eso la historia entra como predictor y no como criterio de exclusión; la etiqueta "sin deserción observada" es solo descriptiva.

**Modelos de conteo explorados (Poisson).** Antes de adoptar la clasificación se exploró una regresión con pérdida de Poisson ponderada por estudiantes, con la historia ajustada como línea base (offset) y un modelo de árboles encima. Esa exploración aportó evidencia que se conserva: la persistencia de la deserción de cada sede es baja (la pendiente de la historia ajustada es de 0,09 a 0,40), las sedes pequeñas introducen ruido que obliga a ajustar las tasas, y el nivel de la tasa cambia entre años, por lo que los conteos esperados deben presentarse con una banda de incertidumbre. Dada la limitación de la profundidad temporal, la modelación final se plantea como clasificación del nivel y de la variación.

**Priorización con alpha (exploración previa).** En la etapa de conteo, la prioridad de una sede combinaba la tasa esperada con su tamaño: tasa esperada multiplicada por el número de estudiantes elevado a un exponente alpha. Con alpha igual a 1 se prioriza por número esperado de estudiantes en riesgo; con alpha igual a 0, por la tasa. Se eligió provisionalmente alpha igual a 0,20 como el mayor valor con el que las sedes pequeñas reciben al menos lo que obtendrían con una lista al azar. En la versión actual, la prioridad combina el nivel y la dirección esperada de la deserción.

**Definición de las variables objetivo.** El nivel de deserción de una sede en el año objetivo se clasifica en cuatro clases: una clase aparte para las sedes con cero desertores observados y tres rangos (bajo, medio y alto) definidos por cortes de percentil sobre la tasa ajustada por contracción de todas las sedes y años con registro positivo. Los cortes se fijan una vez y se mantienen estáticos entre años, para que la variable objetivo sea estable y comparable. La variación compara la tasa del año objetivo con la última tasa conocida, la de hace tres años, y distingue tres clases (baja, igual y sube). Un umbral fijo de variación, como 0,1 puntos porcentuales, marca tantos cambios como los que se observarían si ninguna sede hubiera cambiado, porque las tasas de sedes pequeñas fluctúan por azar; por eso el umbral se define con un límite de embudo sobre el error estándar binomial de la diferencia, en la línea de los gráficos de embudo para comparar instituciones de distinto tamaño (Spiegelhalter, 2005). El nivel de exigencia del límite se calibra evaluando si un modelo aprende la etiqueta mejor que la historia sola.

**Evaluación de los clasificadores (redactar con los resultados de los experimentos 8 y 9).** Los clasificadores se comparan con la persistencia (la clase de hace tres años), con un modelo que solo usa la tasa ajustada de hace tres años, y entre sí, mediante el puntaje F por clase, el kappa de Cohen ponderado cuadráticamente, el área bajo la curva ROC uno contra el resto, y estas métricas ponderadas por el número de estudiantes y desglosadas por estrato de tamaño. La incertidumbre se estima con remuestreo de municipios completos.

**Validación temporal.** La evaluación usa retrocesos temporales: el modelo se entrena con los años objetivo anteriores y se prueba en el siguiente. Con los años disponibles hay tres retrocesos (pruebas 2021, 2022 y 2023); el primero entrena con un solo año. Se complementa con validación agrupada por municipio y con remuestreo por municipio para estimar la incertidumbre. Dado el número limitado de años, los resultados se presentan con sus intervalos y por año, y no con un único valor.

**Explicabilidad.** Los valores SHAP se calculan sobre el modelo de árboles y se agrupan por familias de variables (tamaño y dinámica de matrícula, composición del alumnado, contexto territorial e ICFES), excluyendo la historia propia de la sede, que no es una palanca de política; la regresión multinomial aporta una lectura aditiva mediante sus coeficientes. La explicación no se hace sobre el ensamble final, cuya complejidad dificulta la interpretación. SHAP describe asociaciones del modelo con la predicción y no efectos causales.

**Herramienta.** La herramienta muestra para cada sede el nivel esperado de deserción, la dirección esperada (sube, igual o baja) y los factores principales por familia, y permite descargar las predicciones. Incorpora un laboratorio en el que se pueden subir datos, que solo puntúa y no reentrena. El PSI funciona como alarma cuando los datos subidos se parecen poco a los que el modelo aprendió.

**Introducción a la fase de modelamiento (borrador sin periodos específicos).** La fase de modelamiento tiene como propósito convertir el panel longitudinal de sedes educativas en un instrumento que anticipe, con la información realmente disponible al momento de decidir, en qué nivel de deserción se ubicará cada sede y si ese nivel aumentará, se mantendrá o disminuirá respecto de su historia reciente. Como la deserción es un evento poco frecuente y sus tasas son ruidosas en sedes pequeñas, las variables objetivo se definen a partir de tasas ajustadas por tamaño y con cortes fijos entre años. Se comparan clasificadores basados en árboles y regresiones multinomiales frente a la persistencia, se evalúan con retrocesos temporales y se explican por familias de variables, de manera que las Secretarías de Educación dispongan de una orientación útil para sus acciones de retención.

### 10.3 Párrafos académicos ya entregados (modelo de estilo y texto utilizable)

**Experimento 5 (pesos saturados, capacidad y calibración).** El efecto de la ponderación se observa con claridad: al reemplazar el tamaño de la sede por un peso saturado, n·K/(n+K), con K entre 8 y 15 estimado por Bayes empírico en los años de entrenamiento, la captura total mejora de forma significativa cuando la lista aún atrapa el 20% de los desertores de Q1. En Solo_Primaria la mejora es de +9,8 puntos (IC 95% [+3,9; +11,1]), y también sube la captura dentro del estrato Q5 (+1,1; [+0,5; +1,9]). En ofrecen11 el beneficio es más modesto: +0,8 en la captura media dentro del estrato y +2,2 en la frontera. Su costo es una devianza ligeramente mayor (+0,09 sobre ~21, es decir 0,4%), esperable porque esta métrica pondera por n. Con la capacidad intermedia (100 árboles, `min_child_samples` = 150) se obtiene el mejor equilibrio entre paneles: el modelo de 150 árboles sobreajusta en Solo_Primaria (devianza +0,014 y −0,49 puntos de captura media frente a c2) y el de 50 árboles subajusta en ofrecen11 (+0,19 de devianza). El criterio para fijar la configuración fue elegir la combinación que no empeora significativamente a ningún panel en ninguna métrica principal; bajo ese criterio, B2 con pesos saturados y capacidad c2 se adopta como modelo de trabajo. La pendiente del GLM sobre la historia (0,09-0,30 en Solo_Primaria y 0,32-0,40 en ofrecen11) muestra que la persistencia de la deserción en cada sede es baja, lo que justifica explicar el resto de las variables. Por último, la sobrepredicción de 12-20% en Solo_Primaria obedece a una deriva del nivel observado (de 3,75% a 2,95% entre 2020 y 2023): el reescalado con el factor del año anterior la corrige allí, pero la empeora en ofrecen11, donde la tasa sube en 2021 y luego revierte. Los conteos esperados deben presentarse, por tanto, con una banda de incertidumbre de nivel de ±15%, y el ranking relativo es el producto confiable del modelo.

**Experimento 6 (SHAP por familias).** La contribución de cada familia de variables se calculó como el efecto neto absoluto medio por sede, obtenido con TreeSHAP sobre el modelo B2 (offset de historia, pesos saturados y capacidad c2), y se reporta aparte la familia de historia propia, que concentra el 63,8% de la contribución total en el panel con grado 11 y el 40,9% en el de solo primaria. Al excluirla, el peso se reparte de manera distinta en cada panel: en el de grado 11 domina ICFES con el 72,2% [IC 95%: 69,4-74,8] del efecto restante, frente a 10,7% de tamaño y dinámica de matrícula, 8,7% de composición del alumnado y 8,4% de contexto territorial, mientras que en el de solo primaria predomina el contexto territorial con el 56,7% [55,2-57,8], seguido de la composición del alumnado con 27,8% [26,7-29,4] y de tamaño y dinámica de matrícula con 15,4% [15,0-15,8]. El orden entre familias es estable entre los años de prueba, no así su magnitud, pues la participación de ICFES pasó de 45,4% a 72,2% entre 2021 y 2023 a medida que crecía la ventana de entrenamiento. Dentro de la lista prioritaria del 10% construida con α = 0,20, ICFES es la familia que más eleva el riesgo en el 88,6% de las sedes del panel con grado 11 (62,1% fuera de la lista), y el contexto territorial y la composición lo son en el 40,7% y el 50,4% de las del panel de solo primaria; no obstante, el efecto medio de la historia en la lista (+153% y +81%) supera ampliamente al de estas familias (+12,7% y entre +8% y +14%), por lo que estas modulan la explicación del riesgo más de lo que determinan quién entra en la lista. En cuanto al criterio de α, que exige la mayor captura total con una captura Q1 no inferior al 10% de una lista al azar, el modelo B2 lo cumple en ambos paneles tanto con α = 0,20 (19,3% y 18,7%, es decir 1,9 veces el azar) como con α = 0,25 (13,5% y 14,4%), de modo que el umbral exacto se ubica por encima de 0,25 y debe fijarse con una búsqueda más fina; en solo primaria, sin embargo, la captura Q1 varía entre 7,5% y 33,9% según el año, y en 2021 queda por debajo del azar.

**Experimento 7 (definición de los objetivos de clasificación).** La definición de las variables objetivo se evaluó con tres criterios: la estabilidad de los cortes estáticos, la composición por tamaño de las clases y la capacidad de distinguir cambio real de ruido muestral. Con la tasa observada, la clase Alto se concentra en sedes pequeñas (en solo primaria, el 34,1% de las sedes Alto pertenece al quintil de menor tamaño y solo el 3,0% al de mayor tamaño, con cortes P50-P90), mientras que con la tasa ajustada por Bayes empírico (K = 10,9 en solo primaria y 15,8 en el panel con grado 11) la composición se equilibra (entre 15,8% y 28,3% por quintil), por lo que se adopta la tasa ajustada para definir los rangos, manteniendo el cero observado como clase aparte (75-77% de las sedes de solo primaria y 40,9-46,3% de las del panel con grado 11). Los cortes estáticos conservan proporciones estables entre 2020 y 2023 (en solo primaria, la clase cero oscila entre 75,3% y 77,1%). La clase de hace tres años es una predicción débil de la actual: el kappa cuadrático de persistencia es 0,24-0,29 en solo primaria y 0,37-0,44 en grado 11, y solo entre 6,7% y 19,9% de las sedes Alto de solo primaria lo siguen siendo, lo que fija la línea base que deben superar los clasificadores. Los rezagos de cuatro y cinco años son tan informativos como el de tres (correlación de Spearman con la tasa en t de 0,142 y 0,134 frente a 0,119 en solo primaria; 0,419 y 0,406 frente a 0,389 en grado 11), y su agrupación casi duplica la señal en solo primaria (0,232) y la mejora en grado 11 (0,471), por lo que se incorporan a la ventana de rezagos. Para la variación, los umbrales fijos y relativos detectan principalmente ruido: la razón entre los cambios esperados en ausencia de cambio real y los observados fue de 0,92 a 1,12 en solo primaria y de 0,55 a 1,02 en grado 11, mientras que el límite de embudo del 95% (Spiegelhalter, 2005) la reduce a 0,18 y 0,08, aunque clasifica como cambio solo al 14,2% y al 40,4% de las sedes, respectivamente. Dado que la regresión a la media es marcada (el 69,9% de las sedes Alto en solo primaria y el 67,9% en grado 11 pasan a Baja), el criterio para fijar el umbral es el nivel de exigencia más bajo con el que la proporción de cambios atribuibles al ruido siga siendo moderada y el modelo conserve capacidad predictiva por encima de la historia sola, lo que se evalúa en el siguiente experimento.

**Experimento 8 (aprendibilidad de los objetivos de clasificación).** La aprendibilidad empírica de los objetivos se evaluó comparando un modelo completo de gradiente potenciado (21 a 23 covariables y rezagos hasta t-5) frente a un modelo de solo historia rezagada a tres años y frente a la persistencia estática, en tres retrocesos temporales agrupados entre 2021 y 2023. Para el nivel de deserción, el esquema de terciles sobre la tasa ajustada por Bayes empírico superó a los esquemas basados en percentiles extremos tanto en el panel con grado 11 (kappa cuadrático de 0,484 frente a 0,444 en P50-P90 y 0,392 en P75-P95) como en el de solo primaria (0,234 frente a 0,197 y 0,174), alcanzando mejoras estadísticamente significativas sobre la historia sola (+0,070 con IC 95% [+0,062; +0,080] y +0,035 [+0,024; +0,049], respectivamente), una ganancia significativa sobre la persistencia en el panel con grado 11 (+0,033 [+0,026; +0,039]) y la mayor tasa de captura de sedes en la categoría de mayor riesgo (recall de 48% en grado 11 y 25% en solo primaria), por lo que se adopta como objetivo definitivo de nivel. En cuanto a la variación respecto de la última tasa conocida, la regla de variación fija de 0,1 puntos porcentuales arrojó una razón de ruido sobre cambio observado superior a la unidad en ambos paneles (1,12 en solo primaria y 1,02 en grado 11), confirmando que las reglas determinísticas clasifican fluctuaciones aleatorias propias de muestras pequeñas; en contraste, el límite de embudo binomial con umbral z = 1,28 (intervalo bilateral del 80%) redujo dicha razón a 0,45 en solo primaria y a 0,29 en grado 11, preservó una participación balanceada de las clases minoritarias de cambio (11% que sube y 12% que baja en solo primaria; 25% y 27% en grado 11) y produjo ventajas predictivas significativas del modelo completo sobre la historia sola (+0,050 [+0,043; +0,058] en solo primaria y +0,095 [+0,080; +0,107] en grado 11), con un kappa positivo y creciente en todos los años de prueba (0,518 y 0,492 en 2023). Bajo el criterio de seleccionar el umbral de variación más permisivo que mantenga el ruido por debajo del 50% y garantice una ganancia empírica superior a la regresión a la media, se adopta z = 1,28 como objetivo definitivo de variación, cerrando la fase de premodelamiento.

**Experimento 9 (comparación de modelos base multiclase).** La comparación empírica de familias de clasificadores multiclase frente a las líneas base de persistencia y de solo historia rezagada evidenció una superioridad técnica compartida entre los modelos basados en árboles (Random Forest y XGBoost), que prácticamente empataron en la cúspide de todas las métricas en ambos paneles. En el panel con grado 11, para el nivel de deserción en terciles, XGBoost y Random Forest alcanzaron un kappa cuadrático ponderado de 0,484 y 0,483 (AUC multiclase de 0,754 y 0,756, respectivamente), superando con significancia estadística tanto a la persistencia (+0,033 con IC 95% [+0,027; +0,040] y +0,032 [+0,027; +0,039]) como al modelo de historia sola (+0,070 [+0,062; +0,078] y +0,069 [+0,062; +0,078]), al tiempo que la regresión logística multinomial ocupó un tercer lugar con un kappa de 0,459 (AUC de 0,729). En la variación binomial relativa (z = 1,28), XGBoost obtuvo en dicho panel un kappa de 0,354 y un macro-F1 de 0,593 (AUC de 0,797), frente a 0,339 y 0,590 de Random Forest y 0,329 y 0,562 del logit multinomial, mejorando todos sustancialmente a la historia rezagada (+0,096 [+0,081; +0,108] para XGBoost) y a la persistencia estática (que rinde cero al predecir siempre ausencia de cambio). En el panel de solo primaria, Random Forest lideró marginalmente la predicción del nivel con un kappa de 0,243 (AUC de 0,769) sobre XGBoost (0,235; AUC de 0,768) y el logit multinomial (0,208; AUC de 0,745), superando a la historia sola (+0,044 [+0,034; +0,057]); mientras que en la variación, XGBoost y Random Forest alcanzaron un kappa de 0,413 y 0,408 (AUC de 0,858 y 0,855; macro-F1 de 0,617 y 0,614), superando a la historia (+0,050 [+0,042; +0,060] y +0,045 [+0,039; +0,054]) y exhibiendo un desempeño sobresaliente en las sedes más pequeñas del estrato Q1 (kappa de 0,553 y 0,547 frente a 0,352 y 0,349 en Q5), lo que valida que el umbral binomial amortiguó eficazmente el ruido muestral. Bajo el criterio de seleccionar los algoritmos que maximicen el equilibrio de discriminación global, captura de las clases extremas de riesgo y estabilidad temporal sin degradar la equidad por tamaño de sede, se adoptan XGBoost y Random Forest como las arquitecturas principales para el afinamiento de hiperparámetros, manteniendo la regresión multinomial como referencia aditiva interpretable.

Los experimentos 1 a 4 no tienen párrafo académico entregado; se pueden redactar con las secciones 11.1 a 11.5 del handover técnico.

---

## 11. Fórmulas (texto plano, para el capítulo metodológico)

- Tasa de la sede: r = d / n, con d desertores y n estudiantes del año.
- Tasa ajustada: r_aj = (d + K m) / (n + K), con m la tasa media y K la fuerza del ajuste.
- K por empirical Bayes (método de momentos, Kleinman): rho = (S / (m (1 - m)) - (N - 1)) / (sum(n_i) - N), con S = sum(n_i (r_i - m)^2) y N sedes; K = (1 - rho) / rho.
- Peso saturado: w = n K / (n + K).
- Clase de nivel: 0 si d = 0; en otro caso 1, 2 o 3 según la posición de r_aj respecto de los cortes c1 y c2 (percentiles de las tasas ajustadas positivas de todas las sedes y años con registro).
- Variación: delta = r_t - r_(t-3); p0 = (d_t + d_(t-3) + K m) / (n_t + n_(t-3) + K); error estándar se = raíz( p0 (1 - p0) (1 / n_t + 1 / n_(t-3)) ); la clase es "sube" si delta > z se, "baja" si delta < -z se, "igual" en otro caso (z = 1,96 equivale a un límite de embudo del 95%; 3,09 al 99,8%).
- Factor de sobredispersión robusto: phi = max(1, (1,4826 × MAD(z_i))^2), con z_i = delta_i / se_i.
- Cambio falso: porcentaje de sedes marcadas como "baja" o "sube" cuando ambos años se simulan de una binomial con la misma tasa p0 (ninguna sede cambia).
- Kappa cuadrático ponderado: kappa = 1 - sum(w_ij O_ij) / sum(w_ij E_ij), con w_ij = (i - j)^2 / (C - 1)^2, O la matriz de confusión normalizada y E el producto de sus marginales.
- F1 de la clase c: 2 TP / (2 TP + FP + FN); macro-F1 = promedio de los F1 de las clases con soporte.
- Persistencia: se predice la clase de t con la clase que tenía la sede en t-3.
- Poisson (etapa previa): esperado mu = n × r, con r = exp(b0 + b1 x1 + ...); desviación D = 2 sum( d ln(d / mu) - (d - mu) ), con el primer término igual a 0 cuando d = 0.
- PSI = sum( (q_i - p_i) ln(q_i / p_i) ) sobre 10 cajas con el mismo número de sedes del entrenamiento. Umbrales prácticos: menos de 0,10 estable, 0,10 a 0,25 moderado, más de 0,25 cambio grande.
- SMD = (media prueba - media entrenamiento) / raíz((varianza entrenamiento + varianza prueba) / 2).
- Captura del 10% y captura dentro del estrato: ver el handover técnico, sección 11.

---

## 12. Literatura y referencias (verificar antes de citar)

**Encontradas por búsqueda web en las sesiones (no se leyó el texto completo; confirmar datos bibliográficos):**
- Kane, T. y Staiger, D. (2002), "The Promise and Pitfalls of Using Imprecise School Accountability Measures", *Journal of Economic Perspectives*, 16(4), 91-114 (ficha en RePEc/EconPapers; versión de trabajo NBER w8156). Idea usada: las unidades pequeñas quedan desproporcionadamente en los extremos y buena parte del cambio año a año es ruido muestral (en los datos de puntajes que analizan); proponen filtrar por Bayes empírico.
- Spiegelhalter, D. (2005), "Funnel plots for comparing institutional performance", *Statistics in Medicine* (verificar volumen y páginas). Límites de control a 2 y 3 desviaciones estándar (95% y 99,8%) sobre una binomial, con ajuste por sobredispersión. Documentación práctica en el paquete `FunnelPlotR`.
- Spiegelhalter y coautores (2012) sobre métodos estadísticos de regulación en salud (calificación, tamizaje y vigilancia) para el ajuste de sobredispersión (verificar referencia exacta).
- Trabajo de estabilización bayesiana de medidas de desempeño escolar (resultados de búsqueda en eScholarship y en una nota de UNESCO "Beyond the noise"; identificar autores y año antes de citar).
- Modelos de dos partes (hurdle) para resultados con muchos ceros: https://metricgate.com/calculator/two-part-models y https://towardsdatascience.com/two-stage-hurdle-models-predicting-zero-inflated-outcomes/ (fuentes informales; buscar respaldo académico).
- Sistema de alerta temprana de deserción con aprendizaje automático en Corea (árbol con refuerzo, más de 165 mil estudiantes): https://pure.ewha.ac.kr/en/publications/the-machine-learning-based-dropout-early-warning-system-for-impro/
- Sistema de alerta temprana en Gujarat (modelo por grado y SHAP): https://aiopportunity.wadhwaniai.org/main-page-dev-lib/ews
- Explicación de ensambles con valores de Shapley (linealidad): arXiv 2105.00108, "Explaining a Series of Models by Propagating Shapley Values".
- Predicción de deserción en la educación media desde el fin de la primaria con aprendizaje automático: arXiv 2403.14663 (aparecida en una búsqueda; no revisada).
- Gradient boosting para datos con muchos ceros (seguros): arXiv 2307.07771.

**Referencias clásicas propuestas de memoria, no recuperadas (verificar autores, año y título):** Kleinman (1973) para el estimador de momentos del Beta-Binomial; Cohen (1960, 1968) para kappa y kappa ponderado; McCullagh y Nelder, *Generalized Linear Models*; Cameron y Trivedi, *Regression Analysis of Count Data*; Zou y Hastie (2005) para Elastic Net; Breiman (2001) para Random Forest; Chen y Guestrin (2016) para XGBoost; Ke y coautores (2017) para LightGBM; Lundberg y Lee (2017) y Lundberg y coautores (2020) para SHAP y TreeSHAP; Wolpert (1992) para stacking; James y coautores, *An Introduction to Statistical Learning*; Molnar, *Interpretable Machine Learning*.

---

## 13. Figuras y tablas útiles para la tesis

Ya generadas: Fase 2, carpeta `Data\Auditorio_Panel_Final\Figuras\` (una por panel): matriz de correlación de Spearman, VIF, PSI, faltantes, target por año con ceros y cortes, concentración de PRIORITARIO por tamaño con y sin ajuste. Fase 1, carpeta `Data\Processed\Auditoria_Panel\Figuras\`: tendencia del target, faltantes, asociación con el target, matriz de correlación y VIF, y un PDF por panel. Experimento 5: frontera captura total contra captura Q1. Experimento 6: `pre_modelo_shap_familias.png` (participación por familia con y sin historia).

Tablas candidatas (de los `.md` de `Data\Auditorio_Panel_Final`): target por año con cortes, filas por segmento, concentración por tamaño, faltantes, PSI, SMD, VIF y Spearman, persistencia de ceros, comparación de métodos de tamaño, tabla de alpha, experimento de historia, offset, pesos y capacidad, participación por familia, y del experimento 7: valor de los rezagos, composición de "Alto" por tamaño, persistencia de clases, ruido de las reglas de variación, regresión a la media.

Figuras que faltan: diagrama del pipeline (de las fuentes a la herramienta), razón ruido/cambio y kappa contra z, matrices de confusión por clase, curva ROC multiclase, calibración de probabilidades, SHAP por familias de la clase "Alto" y "Sube", y una captura de pantalla de la herramienta.

---

## 14. Limitaciones que el texto debe declarar

- El panel tiene pocos años objetivo modelables (2020 a 2023, tres retrocesos temporales; el primero entrena con un solo año), de los cuales uno coincide con la pandemia; los resultados por año y sus intervalos importan más que un solo valor.
- Con los rezagos de tres a cinco años, los años objetivo completos se reducen (solo 2022 y 2023 tienen los tres rezagos); los faltantes se manejan con valores nulos o imputación.
- El desfase de un año de la situación académica es información dada por el usuario, no verificada con la fuente oficial.
- La imputación de ceros en sedes sin registro es un supuesto; la bandera permite sensibilidades.
- El porcentaje de ceros del target es muy alto en el panel sin ICFES (76 a 77% de las sedes con registro) y hay sedes con muy pocos estudiantes: las tasas son ruidosas y los rangos y la variación de sedes pequeñas son frágiles.
- La persistencia de la deserción de cada sede es baja (pendiente de la historia ajustada de 0,09 a 0,40), y la variación está dominada por la regresión a la media: las sedes de nivel alto tienden a bajar solas.
- El nivel de la tasa cambia entre años (en solo primaria cae de 3,75% a 2,95% entre 2020 y 2023); los cortes estáticos mantienen la definición del objetivo, pero la proporción de sedes en cada clase puede moverse.
- Los cortes estáticos y la contracción usan todos los años disponibles (constantes de etiquetado); la fuga es despreciable pero se declara.
- Los experimentos previos usaron modelos globales y pocos modelos de árboles con parámetros fijos; la afinación anidada está pendiente.
- SHAP muestra asociaciones, no causalidad; las recomendaciones de intervención deben formularse como prioridades de atención. La familia de ICFES concentra buena parte de la explicación en el panel con grado 11 y no se ha confirmado si es una palanca o un marcador socioeconómico.
- La metodología de la categoría de ruralidad del DNP no se ha revisado ante un posible riesgo de filtración de información.
- Pandemia: sin tratamiento propio; solo sensibilidades planeadas.
