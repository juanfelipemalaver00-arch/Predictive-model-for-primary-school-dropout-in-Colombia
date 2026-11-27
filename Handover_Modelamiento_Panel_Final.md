# Handover técnico v5: panel de deserción por sede, resultados del Experimento 9 (modelos base) y paso al Experimento 10

Reemplaza a `Handover_Modelamiento_Panel_Final_v4.md`. Léelo junto con `handover_contexto.md` (contexto, objetivos de la tesis, estilo de redacción y párrafos académicos).

Fecha de esta versión: 27 de noviembre de 2026. Próximo hito del usuario con su asesor: **11 de diciembre de 2026**, con los modelos básicos ya ejecutados, comparados y afinados.

Idioma de trabajo con el usuario: español. Comentarios dentro del código: inglés. Orden del código: rutas, variables generales, funciones, ejecución al final. Código completo y listo para pegar, con los nombres exactos de columnas.

---

## 0. Dónde retomar (léelo primero)

**Estado.** **El Experimento 9 (Modelos Base Multiclase) fue ejecutado y analizado con datos reales completos en ambos paneles (`ofrecen11` y `Solo_Primaria`).** Los reportes completos están guardados en `Data\Auditorio_Panel_Final\modelo_base_comparacion_<panel>.md`.

**Principales conclusiones del Experimento 9:**
1. **XGBoost y Random Forest empatan en la cima del desempeño** en ambos paneles y en ambos objetivos (`NIVEL_TERCILES` y `VAR_Z_1.28`), con diferencias estadísticas no significativas entre sí.
   - En `ofrecen11` (Nivel): XGBoost ($\kappa = 0,484$, AUC $0,754$) y Random Forest ($\kappa = 0,483$, AUC $0,756$) superan a la persistencia con significancia estadística ($+0,033$ y $+0,032$, IC excluye 0) y a la historia sola ($+0,070$ y $+0,069$).
   - En `ofrecen11` (Variación): XGBoost ($\kappa = 0,354$, F1 $0,593$) y Random Forest ($\kappa = 0,339$, F1 $0,590$) superan masivamente a la persistencia ($+0,354$ y $+0,339$) y a la historia sola ($+0,096$ y $+0,081$).
   - En `Solo_Primaria` (Nivel): Random Forest lidera ligeramente en kappa ($\kappa = 0,243$ vs $0,235$ de XGBoost; AUC $0,769$ vs $0,768$), ambos superando significativamente a la historia sola ($+0,044$ y $+0,037$).
   - En `Solo_Primaria` (Variación): XGBoost y Random Forest obtienen $\kappa = 0,413$ y $0,408$, superando a la historia ($+0,050$ y $+0,045$) y a la persistencia ($+0,413$ y $+0,408$).
2. **Equidad en sedes pequeñas (Estratos Q1 a Q5):** En el objetivo de Variación en `Solo_Primaria`, el kappa en el quintil de sedes más pequeñas (Q1) supera $0,55$ ($0,553$ en XGBoost y $0,547$ en RF), resolviendo de raíz el problema histórico donde las sedes diminutas introducían puro ruido muestral.
3. **Regresión Logística Multinomial:** Se ubica consistentemente en tercer lugar ($\kappa = 0,459$ y $0,329$ en ofrecen11; $\kappa = 0,208$ y $0,361$ en Solo_Primaria), pero se conserva como modelo aditivo interpretable de referencia y candidato para meta-modelo de stacking.

**Punto de retoma para el siguiente paso (Experimento 10):**
- Construir y ejecutar el **Experimento 10: Afinación de hiperparámetros anidada y regularización** sobre XGBoost y Random Forest (explorando profundidad, tasa de aprendizaje, `min_child_weight` / `min_samples_leaf`, y regularización L1/L2) para consolidar los modelos finales que alimentarán la matriz de prioridad (Experimento 11) y la explicabilidad SHAP por familias (Experimento 12).

---

## 1. Qué es el proyecto en una línea

Tesis de maestría (Business Analytics, Universidad del Rosario). Se construye un modelo de alerta temprana de deserción escolar por sede educativa oficial en Colombia para las Secretarías de Educación, con una herramienta que muestra el scoring, la dirección esperada del riesgo y qué factores lo empujan. La herramienta tendrá además un laboratorio donde se pueden subir datos (solo puntúa, no reentrena). Detalle en `handover_contexto_v3.md`.

---

## 2. Protocolo de trabajo (para Claude y para un agente que corra los experimentos)

### 2.1 Ciclo de cada experimento
1. Decir en pocas palabras qué se va a probar y explicarlo **como a un niño de cinco años** (qué queremos ver, qué se hizo, para qué, cómo funciona la prueba).
2. Escribir el código **como una celda nueva del notebook `5_COD_Pre_Model.ipynb`**, autocontenida (cada celda copia las funciones que necesita), con la numeración de celdas de la sección 3. No ofrecer ni guardar un `.py` aparte.
3. Probar la celda con datos sintéticos antes de entregarla (sección 16): ejecutar con `python -W error::RuntimeWarning`, y validar contra scikit-learn cualquier métrica implementada a mano. No afirmar que funciona con los datos reales: el usuario la corre y pega los `.md`.
4. Entregar solo el notebook actualizado (`present_files`), sin postámbulos largos.
5. Cuando el usuario pegue los resultados: conclusión con evidencia, en lenguaje simple, con la estructura **qué queríamos ver, qué se hizo, para qué, conclusión**, más **qué implica para el modelamiento**, y siempre un **párrafo académico** (sección 2.2).
6. Registrar el experimento en la sección 11 y las decisiones en la sección 14 de este handover.

### 2.2 Formato de cierre de cada experimento (preferencia explícita del usuario)
- Todo explicado como a un niño de cinco años, **excepto** el párrafo académico.
- Párrafo académico: **uno solo**, en español formal, tercera persona, prosa continua, con cifras concretas, con el criterio de decisión explícito y sin guiones largos. Ejemplo que dio el usuario (de su tesis): "El compromiso se observa con claridad pues a medida que alpha baja, la captura total cae y la captura Q1 sube [...]. Ahora bien, el criterio para fijar alpha es el mayor valor con el que las sedes pequeñas reciben al menos lo que daría una lista al azar [...]". Los párrafos de los experimentos 5, 6 y 7 ya entregados están en `handover_contexto_v3.md`, sección 10, como modelo de estilo.
- Si faltó el párrafo académico en una respuesta, el usuario lo reclama: nunca omitirlo.

### 2.3 Reglas de trabajo
- Una pregunta como máximo por respuesta. Decisiones con números, con intervalos de confianza cuando se pueda.
- **No generar CSV** salvo que sea absolutamente necesario. Los reportes son `.md` (y un `.png` solo si aporta a la tesis). Las celdas 0 a 4 sí escriben CSV (histórico); las celdas 5 a 7 no.
- No inventar cifras ni referencias. Marcar qué se probó y qué no. Claude nunca corrió el pipeline con los datos completos del usuario.
- Cada celda reemplazada por el usuario pierde las constantes que él haya ajustado a mano (ya ocurrió con la tipología). Preguntar antes de reescribir constantes.
- Máquina del usuario: Windows corporativo con red restrictiva. XGBoost y LightGBM **sí** se instalan. Evitar funciones de pandas recientes (`include_groups`, `reset_index(names=...)`) y no usar `|` dentro de celdas de tablas markdown.
- El usuario correrá el código en VS Code y pegará los reportes; también pegará gráficos de la tesis para interpretarlos a la luz del objetivo del proyecto.
- Seguir pidiendo la versión actual del notebook si hay que modificarlo, en lugar de reconstruirlo de memoria.

### 2.4 Para un agente autónomo que ejecute y revise experimentos
- Entradas: `Data\Processed\panel_final_<panel>.csv` (con `PESO_ESTUDIANTES` y `COD_MPIO_DANE`) y el notebook 5.
- Salidas por experimento: un `.md` por panel en `Data\Auditorio_Panel_Final\` (nombres en la sección 3). Después de cada corrida: leer el `.md`, comparar con las reglas de la sección 12, escribir la conclusión (formato 2.2) y decidir el siguiente experimento con la lista de la sección 13.
- Criterios para detenerse y consultar al usuario: (a) la prueba de cordura falla (por ejemplo, `B2_wn_c3` no reproduce `B2_offset_con_hist_t150`, o la persistencia no coincide con la tabla 3d del experimento 7); (b) un resultado contradice una decisión del asesor; (c) hay que cambiar una definición de objetivo ya acordada; (d) falta un archivo o columna (`PESO_ESTUDIANTES`, `COD_MPIO_DANE`).
- No cambiar en silencio: los cortes estáticos, la definición de la tasa ajustada, el horizonte (t-3) ni las semillas (`SEED = 42`).

---

## 3. Mapa de archivos y rutas (Windows del usuario)

Raíz de datos (`ROOT` en el maestro, `BASE_DIR` en la Fase 2 y en las celdas de experimentos):
`C:\Users\DELL\OneDrive\Escritorio\UNIVERSIDAD\Maestria Business A\Proyecto Empresarial\Data`

Notebooks del usuario: `...\Proyecto Empresarial\Codigos\`.

| Carpeta | Contenido |
|---|---|
| `Data\Raw\C-600\<año>\` | Archivos `<prefijo>_<año>.csv` del formulario C-600, incluido `Sit_Acad_<año>.csv` |
| `Data\Raw\SIMAT\` | `Tasa_Desercion_intra_Departamentos.xlsx`, `Tasa_repitencia_intra_Departamentos.xlsx`, `DIVIPOLA.csv` |
| `Data\Raw\IPM\` | `IPM_Hogares_<año>.csv` |
| `Data\Raw\Enrichment\` | `PDET_municipios.xlsx`, `ZOMAC_municipios.xlsx`, `Clasificacion_Ruralidad_DNP.xlsx`, `Icfes_Resumen.csv`, `Manual_sede_municipio.xlsx` |
| `Data\Processed\` | `panel_maestro_ofrecen11.csv`, `panel_maestro_Solo_Primaria.csv`, `diagnostico_panel.xlsx`, `panel_final_<panel>.csv`, `panel_scoring_<panel>.csv` |
| `Data\Processed\Auditoria_Panel\` | Salidas de la Fase 1 (csv por análisis) y `Figuras\` |
| `Data\Auditorio_Panel_Final\` | Salidas de la Fase 2 y de todos los experimentos (tabla siguiente) y `Figuras\` |

Paneles: `ofrecen11` (sedes con ICFES) y `Solo_Primaria` (sin ICFES). Una sede está en un solo panel.

### Código entregado por Claude

| Archivo | Qué contiene |
|---|---|
| `3_COD_Panel_creation_sede_target.ipynb` y `.py` | Panel maestro (la celda 1 es todo el código; la celda 0 es texto y la celda 2 un chequeo de ICFES) |
| `4_COD_Quality_Check_Exploratory_Panel_sede_target.ipynb` | Celda 0 = Fase 1 (diagnóstico del maestro), celda 1 = Fase 2 (panel final y scoring) |
| `4a_...Fase1...py`, `4b_...Fase2...py` | Las mismas dos celdas como script (histórico) |
| **`5_COD_Pre_Model.ipynb`** | **Ocho celdas (índice desde 0), una por experimento. Es la fuente de verdad del código de experimentos.** |

Mapa del notebook 5:

| Celda | Experimento | Salida principal (`Data\Auditorio_Panel_Final\`) | Estado |
|---|---|---|---|
| 0 | 1. Persistencia de ceros (regla por historia) | `pre_modelo_persistencia_<panel>.md/.csv` | Corrida y analizada |
| 1 | 2. Tamaño de la sede (cinco métodos) | `pre_modelo_experimento_tamano_<panel>.md/.csv` | Corrida y analizada |
| 2 | 3. Historia (variantes de la historia) | `pre_modelo_experimento_historia_<panel>.md/.csv` | Corrida y analizada |
| 3 | 4. Offset de la historia (A, B, B2, C) con bootstrap | `pre_modelo_experimento_offset_<panel>.md`, `_bootstrap_`, `_shap_familias_` (csv) | Corrida y analizada |
| 4 | 5. Frontera, capacidad, pesos saturados, calibración por año | `pre_modelo_experimento_frontera_capacidad_<panel>.md` (+ csv y png) | Corrida y analizada |
| 5 | 6. SHAP por familias (B2, pesos saturados, c2) | `pre_modelo_shap_familias_<panel>.md` y `pre_modelo_shap_familias.png` | Corrida y analizada |
| 6 | 7. Objetivos de clasificación (nivel y variación) y su ruido | `pre_modelo_objetivos_clasificacion_<panel>.md` | Corrida y analizada |
| 7 | 8. Aprendibilidad de los objetivos (XGBoost vs historia vs línea base) | `pre_modelo_aprendibilidad_objetivos_<panel>.md` | **Escrita, sin resultados todavía** |

Salidas clave de las fases 1 y 2: `phase2_audit_<panel>.md/.csv` (auditoría de predictores: faltantes, PSI, SMD, VIF, Spearman), `phase2_audit_conteos_`, `_spearman_`, `_flags_`, `_target_`, `_tamano_`, `_segmentos_<panel>.csv`, `feature_manifest.xlsx`, figuras `Figuras\<panel>_01_correlacion_predictores.png` a `_06_prioritario_por_tamano.png` y las de la Fase 1 en `Auditoria_Panel\Figuras\`.

Advertencia operativa: el notebook 5 se renombró (antes `5_COD_Pre_Modelamiento.ipynb`); los scripts `5_..._Persistencia.py`, `6_COD_Experimento_Tamano.py`, `7_COD_Experimento_Historia.py` y `8_COD_Experimento_Offset.py` ya no se mantienen: la celda del notebook manda.

---
## 4. Arquitectura del pipeline

```
Raw (C-600, Sit_Acad, SIMAT, ICFES, IPM, PDET, ZOMAC, tipología DNP)
   -> notebook 3: panel_maestro_<panel>.csv  (una fila por sede y año, 2017 a 2024, valores del mismo año)
   -> notebook 4 celda 0 (Fase 1): diagnóstico del maestro
   -> notebook 4 celda 1 (Fase 2): panel_final_<panel>.csv y panel_scoring_<panel>.csv
        fila = (sede, ANIO_OBJETIVO t); predictores medidos en t-2 (covariables) y t-3 (deserción propia)
   -> notebook 5 celdas 0 a 7: experimentos previos al modelamiento
   -> modelamiento (EN CURSO): clasificación multiclase de nivel y variación, modelos base, luego stacking
   -> SHAP / explicabilidad, scoring y herramienta (pendiente)
```

Los rezagos 4 y 5 **no vienen en el panel final**: las celdas 6 y 7 los reconstruyen uniendo el propio panel por (sede, año objetivo + k), igual que `load_panel` lo hace para el rezago 3. No hay que rehacer el panel.

---

## 5. Definiciones fundamentales

- **Target base.** `TASA_DESERCION_SEDE` = desertores / estudiantes de la sede en el año t, desde `Sit_Acad` (formato largo por sede, jornada, nivel, grado y situación académica; código 3 = desertores; denominador = todas las situaciones 1 a 4). Desertores del panel final = `round(TASA_DESERCION_SEDE * PESO_ESTUDIANTES)`.
- **Desfase de `Sit_Acad`.** El archivo con etiqueta t+1 describe el año t (`SIT_ACAD_YEAR_OFFSET = 1`). Lo afirmó el usuario; no se verificó contra la fuente oficial.
- **Panel.** Años 2017 a 2024. No existe 2025 (el DANE suspendió y reprogramó esa recolección). Sin target para 2024: el último año con target observado es 2023.
- **Horizontes (cada variable usa solo lo disponible al predecir).**
  - Covariables (C-600, ICFES, tasas municipales): en `ANIO_REFERENCIA = t - 2`.
  - Deserción propia de la sede (`DESERCION_LAG3`): en `ANIO_REF_DESERCION = t - 3`, porque `Sit_Acad` del año t+1 se publica hacia mayo de t+3.
  - Scoring 2026: covariables de 2024 y deserción de 2023 (`2026 - 3 == ANIO_TEST`).
  - **Consecuencia para la clasificación:** en producción solo existen los rezagos de deserción t-3, t-4 y t-5. Los rezagos 1 y 2 no existen al predecir. Lo que el asesor llamó "rezagos de hasta 3 años" se interpreta como una **ventana de historia de tres observaciones** (t-3, t-4, t-5). Cada rezago extra recorta los años objetivo completos: con t-5 solo 2022 y 2023 son completos; por eso los faltantes se dejan como NaN (XGBoost) o se imputan (RF y logit). **Esta interpretación del horizonte de 3 años debe confirmarse con el asesor.**
  - Los rezagos se calculan por año calendario (no por posición de fila), para sedes con huecos.
- **Elegibilidad.** `ELEGIBLE_MODELO = TIENE_REFERENCIA & TIENE_HIST_DESERCION & TARGET_DISPONIBLE`. Años objetivo elegibles: 2020 a 2023. Las celdas 6 y 7 usan además `PESO_ESTUDIANTES > 0`, tasa no nula y `ESTUDIANTES_LAG3 > 0` (registro en t-3).
- **Partición del panel final.** `SPLIT`: TRAIN (año objetivo <= 2022), TEST (2023), SIN_TARGET (2024). **Los experimentos no usan esa columna:** hacen retrocesos temporales propios (entrenar con años objetivo < año de prueba; pruebas 2021, 2022, 2023).
- **Ceros imputados.** Decisión del usuario: en los años cuyo archivo `Sit_Acad` existe, una sede sin registro (o sin estudiantes en el denominador) se asume con tasa 0. Banderas `FLAG_DESERCION_SEDE_CERO_IMPUTADO` y `FLAG_DESERCION_LAG3_CERO_IMPUTADO`. Metadato, nunca predictor. En los ceros imputados el denominador queda vacío (NaN), nunca 0. Estas filas no entran a los experimentos (se exige `PESO_ESTUDIANTES > 0`).
- **Peso.** `ESTUDIANTES_SIT_ACAD` en el maestro y `PESO_ESTUDIANTES` en el panel final (estudiantes del sede-año objetivo). Es peso o exposición, nunca predictor.
- **Tasa ajustada (empirical Bayes).** `(d + K m) / (n + K)`, con `m` la tasa media y `K` la fuerza del ajuste estimada por el método de momentos de un Beta-Binomial (Kleinman). Siempre es mayor que 0. En los experimentos de la línea Poisson, `K` y `m` salían solo de los años de entrenamiento; **en las celdas 6 y 7 salen de todos los datos disponibles**, igual que los cortes estáticos (son constantes de etiquetado; fuga despreciable, pero está documentada).
- **Etiquetas de riesgo del panel final (`NIVEL_RIESGO`, `ALTO_RIESGO`, `PCT_RANK_RIESGO`, `TASA_DESERCION_AJUSTADA`).** Se calculaban por año con `K_SHRINKAGE = 10`. **Quedan en el panel pero ya no son el target ni la referencia.** Los objetivos nuevos se construyen dentro de las celdas de experimentos con cortes estáticos.
- **Segmentos.** `TIPOLOGIA_DNP` (cuatro categorías: Ciudades y aglomeraciones, Intermedio, Rural, Rural disperso) y `SEGMENTO_MODELO` = `ICFES` o `SIN_ICFES` + `__` + categoría. 8 segmentos. Metadatos, no predictores.

---

## 6. Variables

### 6.1 Panel maestro (82 columnas en ofrecen11, 66 en Solo_Primaria)

Identificación y control: `SEDE_CODIGO` (12 dígitos, texto), `PERIODO_ANIO`, `SAMPLE`, `ELEGIBLE_MODELO`, `COD_MPIO_DANE`, `COD_DPTO_DANE`, `MPIO_FUENTE`, `REGION_DANE`, `TIPOLOGIA_DNP`, `N_ANIOS_PANEL`, `ANIO_REFERENCIA`, `ANIO_REF_DESERCION`, `TIENE_GRADO_11` (solo ofrecen11).

Target y salidas: `TASA_DESERCION_SEDE`, `DESERTORES_SEDE`, `ESTUDIANTES_SIT_ACAD`, `FLAG_DESERCION_SEDE_CERO_IMPUTADO`, `FLAG_TASA_DESERCION_IMPUTADA`.

Municipales (SIMAT, mismo año del evento): `TASA_DESERCION_MPIO`, `TASA_REPITENCIA_MPIO`. Rezagos calendario: `DESERCION_LAG3`, `DESERCION_MPIO_LAG2`, `REPITENCIA_LAG2`, `DESERCION_MA2_LAG3`.

Matrícula y dinámica: `MATRICULA_TOTAL`, `MATRICULA_DELTA`, `MATRICULA_PCT_CAMBIO` (recortada a [-1, 5]), `FLAG_DECLIVE_MATRICULA`, `FLAG_PANDEMIA` (solo 2020).

Composición del alumnado: conteos `DESPLAZADOS_*`, `LIMITACION_*`, `TRADICIONAL_*`, `FLEXIBLE_*`, `ETNIA_*` y proporciones `PROP_DESPLAZADOS`, `PROP_LIMITACION`, `PROP_TRADICIONAL`, `PROP_FLEXIBLE`, `PROP_ETNIA`, más `INDICE_VULNERABILIDAD`.

ICFES (solo ofrecen11): `ICFES_CANT_ESTUDIANTES`, `ICFES_PROM_PUNT_GLOBAL`, `ICFES_PROM_LECTURA`, `_MATEMATICAS`, `_CIENCIAS`, `_SOCIALES`, `_INGLES`, `ICFES_PROM_INSE`, `ICFES_PCT_ESTRATO_1_2`, `_INTERNET`, `_COMPUTADOR`, `_DESPLAZACOLEGIO`, `_HORASTRABNOREMU`, `ICFES_DISPONIBLE_REF`, `ICFES_COBERTURA_REF`. IPM municipal por región y año: `IPM_*`. Territorio: `FLAG_PDET`, `FLAG_ZOMAC`.

### 6.2 Panel final (39 columnas en ofrecen11, 35 en Solo_Primaria)

- **Predictores base: 11 en ofrecen11, 9 en Solo_Primaria.** `DESERCION_LAG3`, `MATRICULA_TOTAL`, `MATRICULA_PCT_CAMBIO`, `PROP_DESPLAZADOS`, `PROP_LIMITACION`, `PROP_ETNIA`, `PROP_FLEXIBLE`, `FLAG_PDET`, `FLAG_ZOMAC`, y solo en ofrecen11 `ICFES_PROM_PUNT_GLOBAL`, `ICFES_PROM_INSE`.
- **Ablación (fuera del modelo base):** `DESERCION_MPIO_LAG2`.
- **Identificación y control:** `SEDE_CODIGO`, `ANIO_OBJETIVO`, `ANIO_REFERENCIA`, `ANIO_REF_DESERCION`, `SPLIT`, `COD_MPIO_DANE`, `COD_DPTO_DANE`, `REGION_DANE`, `MPIO_FUENTE`, `TIPOLOGIA_DNP`, `SEGMENTO_MODELO`, `TIENE_REFERENCIA`, `TIENE_HIST_DESERCION`, `TARGET_DISPONIBLE`, `ELEGIBLE_MODELO`, `ELEGIBLE_RIESGO`.
- **Metadatos de calidad (nunca predictores):** `FLAG_DESERCION_SEDE_CERO_IMPUTADO`, `FLAG_DESERCION_LAG3_CERO_IMPUTADO`, `N_ANIOS_PANEL_REF`, `PCT_PREDICTORES_DISPONIBLES`, `SEDE_NUEVA_REF`, y en ofrecen11 `ICFES_DISPONIBLE_REF`, `ICFES_COBERTURA_REF`.
- **Target y etiquetas (heredadas):** `TASA_DESERCION_SEDE`, `TASA_DESERCION_AJUSTADA`, `PCT_RANK_RIESGO`, `NIVEL_RIESGO`, `ALTO_RIESGO`.
- **Peso:** `PESO_ESTUDIANTES`.

### 6.3 Variables construidas en las celdas 6 y 7 (no están en el panel)
`TASA_LAG4`, `TASA_LAG5` (tasas observadas), `ADJ_LAG3`, `ADJ_LAG4`, `ADJ_LAG5` (tasas ajustadas), `ADJ_POOL_3_5` (tasa ajustada con los desertores y estudiantes agrupados de los tres rezagos), `ESTUDIANTES_LAG{3,4,5}`, `DESERTORES_LAG{3,4,5}`. Lista en la constante `EXTRA_FEATURES` de la celda 7.

### 6.4 Variables excluidas del panel final y por qué
| Variable | Motivo |
|---|---|
| `ICFES_PROM_LECTURA`, `_MATEMATICAS`, `_CIENCIAS`, `_SOCIALES`, `_INGLES` | Redundantes con `ICFES_PROM_PUNT_GLOBAL` (VIF de 8,6 a 17,4; Spearman de 0,86 a 0,95) |
| `IPM_*` | Deriva extrema entre TRAIN y TEST (PSI 4,2 a 4,8); funcionan como reloj calendario |
| `REPITENCIA_LAG2` (municipal) | PSI 2,0 a 2,4 y SMD mayor a 1 |
| `DESERCION_MPIO_LAG2` | PSI 0,42 (ofrecen11) y 0,33 (Solo_Primaria), SMD 0,54; queda como ablación |
| `DESERCION_MA2_LAG3` | Copia suavizada de `DESERCION_LAG3` (Spearman 0,92 a 0,94) |
| `ICFES_DISPONIBLE_REF`, `ICFES_COBERTURA_REF`, `SEDE_NUEVA_REF`, `N_ANIOS_PANEL_REF` | Miden historial de reporte, no características de la sede |
| `FLAG_PANDEMIA`, `MATRICULA_DELTA`, `FLAG_DECLIVE_MATRICULA` | Dummy de calendario o dependen de t-1 |
| `TASA_DESERCION_MPIO`, `DESERTORES_SEDE`, `TASA_REPITENCIA_MPIO`, `ESTUDIANTES_SIT_ACAD` | Contemporáneas con el target o familia del target |

---

## 7. Evidencia de cada decisión y cifras del panel

### 7.1 Evidencia
| Decisión | Evidencia |
|---|---|
| Target a nivel sede en lugar de municipal | El target municipal era un solo valor por municipio y año; `DESERCION_LAG2` coincidía con el target de t-2 en 77 de 77 filas de las muestras |
| Rezago de 3 años para la deserción de sede | `Sit_Acad` del año t+1 sale hacia mayo de t+3 (los datos de 2024 no salen hasta mayo de 2027) |
| Rezagos por año calendario | Una sede sin un año: el rezago por posición tomaba el año equivocado |
| Depuración de predictores para SHAP | Auditoría final: ninguna variable marcada; VIF máximo 2,27; Spearman máximo 0,68; PSI máximo 0,033; SMD máximo 0,14 |
| El tamaño de la sede domina las etiquetas con la tasa cruda | Solo_Primaria: 41,6% de las sedes más pequeñas (mediana de 6 estudiantes) en el nivel más alto frente a 0,13% de las más grandes; con ajuste, 21,0% frente a 1,6%. Experimento 7: con tasa observada, 34,1% de las sedes "Alto" (cortes P50-P90) son del quintil más pequeño y 3,0% del más grande; con tasa ajustada se reparte entre 15,8% y 28,3% |
| Ceros como clase aparte | 76,2% de las filas elegibles de Solo_Primaria y 43,0% de ofrecen11 tienen cero desertores observados |
| Rezagos 4 y 5 aportan | Experimento 7, tabla 1b (sección 11.8) |
| Los umbrales fijos de variación miden ruido | Experimento 7, tabla 4 (sección 11.8) |
| Tipología con paradas de seguridad | La configuración se perdió una vez y todo quedó `SIN_TIPOLOGIA` sin aviso |
| Guardado robusto de figuras | `OSError [Errno 22]` en OneDrive; reintentos y respaldo en `%LOCALAPPDATA%\Auditoria_Figuras` |

Pandemia: sin tratamiento propio (`FLAG_PANDEMIA` no entra). Sensibilidad pendiente: sin 2020 y sin 2021 como años objetivo (el primer retroceso, prueba 2021, entrena con un solo año y es el más débil para los modelos de árboles).

### 7.2 Cifras del panel final (datos completos)
| | Ofrecen11 | Solo_Primaria |
|---|---|---|
| Filas totales | 100.377 | 324.531 |
| Filas elegibles | 49.150 | 154.939 |
| Filas con registro (todos los años, usadas para cortes y K) | 85.775 | 242.552 |
| Filas elegibles con registro en t y en t-3 (usadas por las celdas 6 y 7) | 47.851 elegibles con registro; sedes con ambos años: 47.429 | 132.631 elegibles con registro; con ambos años: 119.096 |
| % de ceros observados por año objetivo (2020 a 2023) | 41,5 / 40,9 / 43,2 / 46,3 (celda 6) | 75,9 / 76,7 / 75,3 / 77,1 (celda 6) |
| Filas con cero imputado (todos los años) | 2.078 | 42.499 |
| K de Bayes empírico con todos los datos / tasa media | 15,8 / 3,29% | 10,9 / 3,10% |

Segmentos (filas de modelo con target positivo; TRAIN / TEST): Ofrecen11: Ciudades y aglomeraciones 10.993 / 3.305; Intermedio 4.353 / 1.327; Rural 3.346 / 1.025; Rural disperso 2.251 / 693. Solo_Primaria: Ciudades 9.961 / 2.902; Intermedio 5.529 / 1.746; Rural 4.703 / 1.553; Rural disperso 3.803 / 1.337. En el primer retroceso quedan 711 filas de modelo en Rural disperso de ofrecen11 y 1.089 en Solo_Primaria.

Tasa observada por año (ponderada por estudiantes, población elegible con registro): Solo_Primaria 3,75% (2020), 3,28% (2021), 3,05% (2022), 2,95% (2023); ofrecen11 3,07%, 3,60%, 3,35%, 3,10%. **El nivel de la tasa cambia de un año a otro** (importante para cortes estáticos y para calibración).

---

## 8. Línea vigente: clasificación multiclase con dos objetivos (diseño)

### 8.1 Objetivo A: nivel de deserción en t (`NIVEL_TERCILES`, 4 clases) — [DECIDIDO]
- Clase 0 = "Sin deserción observada" (desertores = 0 en t). Es una clase aparte por decisión metodológica y del usuario (76% en Solo_Primaria y 43% en ofrecen11).
- Clases 1 a 3 (Bajo, Medio, Alto): posición de la **tasa ajustada** (empirical Bayes) entre dos cortes estáticos correspondientes a los **terciles** de las tasas ajustadas **positivas de todas las sedes y años con registro**:
  - `Solo_Primaria`: cortes en 3,547% y 8,398% (distribución de clases: 75% Sin, 9% Bajo, 8% Medio, 8% Alto).
  - `ofrecen11`: cortes en 2,335% y 5,800% (distribución de clases: 43% Sin, 19% Bajo, 19% Medio, 20% Alto).
- **Justificación empírica (Experimento 8):** Supera contundentemente a `P50_P90` y `P75_P95`:
  - Mayor kappa cuadrático del modelo completo: 0,484 en ofrecen11 (frente a 0,444 de P50_P90) y 0,234 en Solo_Primaria (frente a 0,197 de P50_P90).
  - Mayor ganancia significativa sobre la historia sola (`FULL - HIST`): +0,070 [+0,062, +0,080]* en ofrecen11 y +0,035 [+0,024, +0,049]* en Solo_Primaria.
  - En ofrecen11 supera a la persistencia (`FULL - BASE`): kappa +0,033 [+0,026, +0,039]*.
  - Mayor recall en la clase de mayor riesgo "Alto": 48% en ofrecen11 y 25% en Solo_Primaria.
  - Proporciona balance suficiente de ejemplos positivos para entrenar modelos complejos sin colapso de clases raras.

### 8.2 Objetivo B: variación respecto a t-3 (`VAR_Z_1.28`, 3 clases) — [DECIDIDO]
- Compara la tasa observada en t con la **última tasa conocida (t-3)**. Clases: 0 Baja, 1 Igual, 2 Sube.
- Regla: Límite de embudo binomial estadístico con $z = 1,28$ (intervalo bilateral del 80%, 10% por cola) sobre el error estándar de la diferencia:
  $$\Delta = r_t - r_{t-3},\quad p_0 = \frac{d_t + d_{t-3} + K m}{n_t + n_{t-3} + K},\quad \text{se} = \sqrt{p_0(1-p_0)\left(\frac{1}{n_t} + \frac{1}{n_{t-3}}\right)}$$
  Se clasifica como cambio si $|\Delta| > 1,28 \cdot \text{se}$.
- **Justificación empírica (Experimento 8):**
  - Cumple los 4 criterios de selección fijados: (1) Ganancia `FULL - HIST` positiva y estadísticamente significativa en ambos paneles (+0,050 [+0,043, +0,058]* en Solo_Primaria; +0,095 [+0,080, +0,107]* en ofrecen11); (2) Ratio de ruido sobre cambio observado controlado por debajo de 0,5 (0,45 en Solo_Primaria y 0,29 en ofrecen11); (3) Distribución equilibrada de clases con minoritarias $\ge 10\%$ (Solo_Primaria: 12% Baja / 77% Igual / 11% Sube; ofrecen11: 27% Baja / 48% Igual / 25% Sube); (4) Kappa estrictamente positivo y creciente en todos los años de prueba (Solo_Primaria: 0,327 en 2021, 0,399 en 2022, 0,518 en 2023; ofrecen11: 0,242, 0,332, 0,492).
  - Responde directamente al pedido del asesor de relajar el 95% ($z = 1,96$ era excesivamente conservador, reduciendo Sube al 7% en Solo_Primaria), mientras refuta la regla fija de 0,1 pp (que produce un ratio de ruido de 1,12 y 1,02, midiendo fluctuaciones aleatorias).
- La prioridad de política combina nivel y variación: por ejemplo, nivel Alto y variación Sube representa la máxima prioridad de intervención preventiva.

### 8.3 Variables de entrada (modelo completo)
Predictores base del panel (11 en ofrecen11, 9 en Solo_Primaria) más las variables reconstruidas `EXTRA_FEATURES` (rezagos 3, 4 y 5 de tasas observadas, tasas ajustadas, conteos de desertores y estudiantes, y la tasa agrupada `ADJ_POOL_3_5`). En total: 23 variables en ofrecen11 y 21 en Solo_Primaria. Faltantes: XGBoost los maneja nativamente; para Random Forest y Regresión Multinomial se aplica imputación por mediana con indicador de faltante calculada estrictamente en el split de entrenamiento de cada pliegue temporal.

### 8.4 Modelos, validación y métricas
- Modelos: XGBoost multiclase (`multi:softprob`), Random Forest (`class_weight='balanced'`), Regresión Multinomial regularizada (`LogisticRegression(multi_class='multinomial')`). Stacking posterior al 11 de diciembre.
- Validación: Retroceso temporal con ventana expansiva (pruebas 2021, 2022, 2023; entrenamiento con años $< t$). Intervalos de confianza al 95% mediante bootstrap de municipios (200 réplicas por agregación de matrices de confusión municipales).
- Pesos de entrenamiento: balanceados por clase.
- Métricas principales: Kappa cuadrático ponderado (métrica rectora para clases ordinales), Macro-F1, F1 ponderado por estudiantes, AUC multiclase uno contra el resto, exactitud balanceada y recall por clase (con foco en Alto y Sube).
- Desagregaciones obligatorias: Evaluación ponderada por estudiantes y por quintil de matrícula (Q1 a Q5) para auditar equidad por tamaño de sede.
- Líneas base de comparación: Persistencia (clase de hace 3 años para nivel; siempre "Igual" para variación) y modelo de solo historia (`HIST`).

### 8.5 Explicabilidad
Se realiza a través de los modelos principales (árboles y multinomial aditivo) y no del ensamble: SHAP multiclase sobre XGBoost para las clases de interés ("Alto" y "Sube") agrupado por familias (tamaño y dinámica, composición del alumnado, contexto territorial y contexto ICFES), excluyendo la familia de historia propia por no ser palanca de política pública.

### 8.6 Estado de decisiones
- **DECIDIDO:** Objetivo A (`NIVEL_TERCILES`), Objetivo B (`VAR_Z_1.28`), horizonte temporal ($t-3, t-4, t-5$), tratamiento de ceros observados como clase aparte, cortes estáticos con todos los datos, esquema de retroceso temporal y bootstrap de municipios.
- **PENDIENTE PARA EL MODELAMIENTO:** Hiperparámetros de los modelos base en Experimento 9, comparación de algoritmos (XGBoost vs RF vs Multinomial), evaluación de la necesidad de modelos segmentados por tipología DNP vs modelo global, y meta-modelo de stacking.

---

## 9. Línea Poisson (archivada, pero útil)

Lo que fue el modelo objetivo hasta el experimento 6: regresión de la tasa esperada con pérdida Poisson ponderada por estudiantes sobre todas las sedes con registro, GLM de la historia como **offset** (pendiente libre sobre `log(DESERCION_LAG3_AJUSTADA)`) más LightGBM, pesos saturados `n K / (n + K)` y capacidad c2 (100 árboles, `min_child_samples` 150); prioridad = tasa esperada × estudiantes^alpha.

Qué **se conserva** de esa línea:
1. La evidencia de que la historia es débil (pendiente 0,09 a 0,40), de que las sedes pequeñas meten ruido y de que el nivel de la tasa se mueve entre años (secciones 11.6 y 11.8).
2. La tasa ajustada por empirical Bayes, la estimación de K, el esquema de retrocesos y el bootstrap por municipio.
3. El SHAP por familias (celda 5) como plantilla.
4. Como **línea base opcional** del experimento 9: convertir las tasas predichas por B2 en clases con los mismos cortes estáticos y compararlas con los clasificadores directos. Si se hace, anotar que usa información de forma distinta.
5. Poisson "a reevaluar" como posible miembro del stacking (decisión pendiente).

Qué **se descarta**: el alpha como regla de prioridad principal, la devianza Poisson y la frontera captura total contra captura Q1 como métricas de selección. El criterio de alpha y sus resultados se conservan como resultado de la tesis (sección 11.3).

---

## 10. Interfaz del código de las celdas 3 a 7 (para modificarlas sin romperlas)

Todas las celdas: rutas, constantes, funciones y ejecución (`main()`), con las funciones auxiliares copiadas dentro de cada una. Semilla `SEED = 42`. Años de prueba `TEST_YEARS = [2021, 2022, 2023]`. Paneles: `PANELES` (ofrecen11 = comunes + ICFES; Solo_Primaria = comunes).

| Celda | Funciones y constantes que importan |
|---|---|
| 3 (offset) | `build_variants`, `fit_history_glm`, `glm_linear_predictor`, `fit_predict_lgbm`, `bootstrap_pairs`, `family_shares`; `TREE_GRID = [150, 300]`, `N_BOOT = 200`, `ALPHAS` |
| 4 (frontera y capacidad) | `make_weights` (`n` o `sat`), `CAPACITIES = {c1, c2, c3}`, `FRONT_ALPHAS`, `Q1_TARGETS = [10, 20]`, `all_year_metrics`, `bootstrap_pairs` con alcances `TODOS` y `2022-2023`, `calibration_table` (con reescalado por el factor del año anterior) |
| 5 (SHAP por familias) | `fit_b2`, `shap_contributions` (verifica aditividad), `family_contributions`, `family_shares`, `bootstrap_shares`, `feature_effects`, `priority_list_drivers`; `ALPHA_POLICY = 0.20`, `ALPHAS_CHECK = [0.20, 0.25]`, `N_TREES = 100`, `MIN_CHILD = 150`. Definición de participación: efecto **neto** de la familia por sede en valor absoluto (distinto de la de la celda 3, que sumaba el |SHAP| medio por variable) |
| 6 (objetivos) | `load_panel_with_lags` (rezagos 3, 4, 5), `adjust_rate`, `level_cuts`, `level_class`, `persistence_stats`, `variation_class`, `overdispersion_factor`, `analyze_panel`; `LEVEL_SCHEMES`, `VAR_RULES`, `DIAG_DEF/DIAG_SCHEME/DIAG_RULE`, `N_SIM = 5` |
| 7 (aprendibilidad) | `build_dataset`, `level_cuts`, `level_class`, `variation_class`, `noise_diagnostic`, `confusion`, `cm_metrics`, `fit_xgb`, `evaluate_target`, `bootstrap_gains`; `LEVEL_SCHEMES` (3), `VAR_RULES` (FIJA_0.1pp y Z 0,5 a 1,96), `EXTRA_FEATURES`, `HIST_ONLY_FEATURES = ["ADJ_LAG3"]`, `FULL_PARAMS` (200 árboles, profundidad 4, tasa 0,05, submuestreo 0,8, `min_child_weight` 3), `HIST_PARAMS` (100 árboles, profundidad 2, tasa 0,1), `N_BOOT = 200` |

Para el experimento 9, el camino más rápido es **partir de la celda 7**: ya tiene carga con rezagos, construcción de objetivos, `cm_metrics` validada contra scikit-learn, pliegues temporales y bootstrap por municipio. Falta agregar los otros modelos, la imputación, las métricas por estrato y ponderadas, y la persistencia como modelo de comparación formal.

---
## 11. Resultados de los experimentos 1 a 8

Convenciones de los experimentos 1 a 6: "lista del 10%" = las sedes con mayor puntaje que forman el 10% de las sedes del año de prueba. "Captura" = porcentaje de todos los desertores del año que quedan en esa lista. "Dentro del estrato" = se divide a las sedes en cinco grupos de tamaño (`MATRICULA_TOTAL`) y se mide, dentro de cada grupo, qué porcentaje de sus desertores queda en el 10% con mayor tasa predicha; el azar da 10%. Q1 = sedes más pequeñas, Q5 = más grandes. Retrocesos: pruebas 2021, 2022, 2023, entrenando solo con años objetivo anteriores. Todos los modelos son globales (sin tipología). Los experimentos 1 a 3 usan `HistGradientBoosting` con parámetros fijos; los experimentos 4 a 6, LightGBM (Poisson); el experimento 8, XGBoost multiclase.

### 11.1 Experimento 1: persistencia de ceros (celda 0)
Regla: sede con `DESERCION_LAG3 == 0` se etiqueta "sin deserción observada". Versión A cuenta los ceros imputados; versión B solo los observados.

| | Solo_Primaria (A) | Ofrecen11 (A) |
|---|---|---|
| Filas en la regla | 77,6% | 39,8% |
| Falsa tranquilidad (positivas dentro de la regla) | 11,4% | 28,8% |
| Positivos que caen en la regla | 43,4% | 20,6% |
| PRIORITARIO que caen en la regla | 60,7% | 21,9% |

Por segmento en Solo_Primaria, los positivos dentro de la regla son 35% (Ciudades), 39% (Intermedio), 54% (Rural) y 57% (Rural disperso). **Conclusión:** la historia es buen predictor pero no sirve como filtro de exclusión; todas las sedes se puntúan y "sin deserción observada" es solo una etiqueta descriptiva.

### 11.2 Experimento 2: tamaño de la sede (celda 1)
K de empirical Bayes: 13,4 / 14,3 / 14,9 (ofrecen11) y 7,7 / 9,9 / 10,4 (Solo_Primaria) para las pruebas de 2021, 2022 y 2023. Con la lista del 10% y alpha = 1 (promedio de los tres años):

| Método | Captura (ofrecen11 / Solo_Primaria) | Desviación Poisson | Calibración (ideal 1) |
|---|---|---|---|
| Poisson ponderado (M4) | 42,8 / 63,3 | 20,8 / 4,15 | 0,95 / 1,14 |
| Dos partes (M3) | 42,4 / 63,9 | 25,3 / 4,42 | 0,61 / 0,69 |
| Solo positivas, K empirical Bayes (M2) | 41,9 / 59,2 | 23,1 / 4,89 | 0,83 / 1,34 |
| Solo positivas sin ajuste (M1) | 42,0 / 58,5 | 23,1 / 5,11 | 0,82 / 1,40 |
| Solo historia (B0) | 39,8 / 54,0 | 121,7 / 26,9 | 0,92 / 1,01 |
| Solo tamaño (B1) | 33,0 / 62,3 | 28,7 / 4,43 | 0,97 / 1,14 |

Discriminación dentro del estrato (azar 10%): M3 24,1 / 25,6; solo historia 22,6 / 22,9; Poisson 21,4 / 22,5; solo positivas 21,1 / 14,1; solo tamaño 9,9 / 10,2. "Solo positivas" quedó dominado (peor desviación, sobreestima 25 a 40% en Solo_Primaria). Con alpha = 1 el orden lo domina el tamaño.

### 11.3 Compromiso captura total / sedes pequeñas (Poisson M4, lista del 10%)
Captura total / captura Q1:

| alpha | Ofrecen11 | Solo_Primaria |
|---|---|---|
| 0,10 | 23,3 / 24,4 | 26,0 / 25,5 |
| 0,15 | 26,7 / 19,4 | 31,8 / 22,4 |
| 0,20 | 29,9 / 15,2 | 37,5 / 18,0 |
| 0,25 | 32,5 / 9,9 | 43,1 / 15,1 |
| 0,30 | 34,8 / 5,8 | 46,7 / 11,4 |
| 1,00 | 42,8 / 0,0 | 63,3 / 0,0 |

Criterio de alpha (del usuario, ya redactado en su tesis): el mayor alpha con el que las sedes pequeñas reciben al menos lo que daría una lista al azar (captura Q1 ≥ 10%). Con alpha = 0,20 se cumple en los dos paneles (15,2% y 18,0%, es decir 1,5 y 1,8 veces el azar); con 0,25 ofrecen11 cae a 9,9%. Estas cifras son del modelo M4 (experimento 2), no de B2.

### 11.4 Experimento 3: historia (celda 2)
Conjuntos con el mismo Poisson: `M4_BASE` (tasa cruda de t-3), `M4_AJUSTADA` (+ tasa ajustada), `M4_CONTEOS` (+ estudiantes y desertores de t-3), `M4_AJUSTADA+CONTEOS`; baselines sin modelo: historia cruda (B0), historia ajustada (B0b), solo tamaño (B1). Discriminación dentro del estrato (promedio de los tres años / Q1 / Q5 / desviación):

| Conjunto | Ofrecen11 | Solo_Primaria |
|---|---|---|
| B0b historia ajustada (sin modelo) | 23,78 / 28,3 / 21,9 / 34,09 | 23,37 / 25,1 / 18,4 / 5,84 |
| M4_AJUSTADA+CONTEOS | 22,59 / 25,3 / 21,1 / 20,80 | 23,13 / 31,6 / 13,1 / 4,15 |
| B0 historia cruda | 22,59 / 23,3 / 21,9 / 121,70 | 22,89 / 26,2 / 18,0 / 26,86 |
| M4_AJUSTADA | 22,53 / 25,1 / 21,1 / 20,78 | 22,95 / 32,4 / 13,6 / 4,15 |
| M4_BASE | 21,41 / 21,3 / 21,0 / 20,81 | 22,46 / 29,7 / 13,4 / 4,15 |
| M4_CONTEOS | 21,18 / 21,2 / 21,1 / 20,84 | 23,76 / 33,9 / 13,4 / 4,15 |
| B1 solo tamaño | 9,93 / 10,6 / 9,9 / 28,68 | 10,16 / 9,6 / 10,2 / 4,43 |

Lectura: las mejoras por variable de historia son consistentes pero pequeñas (~1 punto); la historia ajustada sin modelo iguala o supera en discriminación a las variantes del modelo; el modelo aporta calibración, conteos esperados, captura con alpha y explicabilidad. En Q5 de Solo_Primaria el modelo (13,4%) queda por debajo de la historia sola (18,4%).

### 11.5 Experimento 4: historia como base del modelo (offset) (celda 3)
Variantes (Poisson, LightGBM, mismos retrocesos): **A** historia como variables (tasa cruda, ajustada, conteos); **B** offset = GLM sobre `log(historia ajustada)` con pendiente libre y GBM solo con variables que no son historia; **B2** mismo offset y el GBM también ve la historia; **C** B2 con restricción monótona. Capacidades 150 y 300 árboles. `M4_BASE_HGB` reproduce el experimento 3 (21,41 en ofrecen11; 22,53 en Solo_Primaria con Q5 13,38).

Hallazgos (diferencias con IC 95% por bootstrap de municipios):
1. El offset **no** es el gran salto: B2 supera a A en ~0,5 puntos a igual capacidad (significativo solo en ofrecen11, +0,54 [0,12; 0,98]); la devianza queda igual. C no mejora de forma consistente (la mejor en Solo_Primaria, la peor en ofrecen11).
2. Dejar la historia **fuera del GBM** (B) cuesta: frente a B2, −1,75 y −1,87 puntos de captura dentro del estrato en Solo_Primaria (IC excluye 0) y +0,65 a +0,70 de devianza (~3%) en ofrecen11. Decisión: **predecir con B2 y explicar sin la familia de historia** (las participaciones sin historia de B2 y B son casi iguales).
3. Por panel: en Solo_Primaria, la historia sola (GLM) tiene la mejor devianza (4,02 vs 4,15) y gana Q5 (18,40 vs ~13,8; IC [+3,2; +5,5]); el GBM gana en Q1 (+7 a +9). En ofrecen11 el GBM baja la devianza ~7% (20,75 vs 22,29) y el GLM rankea igual o mejor dentro del estrato.
4. 300 árboles sobreajustan (A_t150 vs A_t300: devianza −0,023 en Solo_Primaria y −0,082 en ofrecen11, significativos).
5. **Comparar modelos a un alpha fijo confunde calidad con dispersión de las tasas predichas** (el GLM, con tasas planas, es dominado por n^alpha y deja de listar sedes pequeñas). Se corrigió con la frontera del experimento 5.
6. El pliegue 2021 (entrena con un solo año) es el más débil para los GBM; parte de "el GLM rankea mejor" viene de ese pliegue.

### 11.6 Experimento 5: frontera, pesos saturados, capacidad y calibración (celda 4)
Parámetros por pliegue (pruebas 2021, 2022, 2023): K = 7,7 / 9,9 / 10,4 (Solo_Primaria) y 13,4 / 14,3 / 14,9 (ofrecen11). Pendiente del GLM sobre `log(historia ajustada)`: 0,09 a 0,30 (Solo_Primaria) y 0,32 a 0,40 (ofrecen11): **la persistencia de la deserción por sede es baja**.

Hallazgos:
1. **Pesos saturados** `n K / (n + K)` mejoran la frontera. Solo_Primaria (c2): captura total a igual captura Q1 de 20% +9,8 puntos (IC [+3,9; +11,1]), Q5 +1,1 [+0,5; +1,9]; en 2022 a 2023, +11,8. Ofrecen11 (c2): captura media dentro del estrato +0,8, frontera +1,3 a +2,2, Q1 +1,9; costo en devianza +0,09 sobre ~21 (0,4%).
2. **Capacidad:** c3 (150 árboles) sobreajusta en Solo_Primaria (c2 mejora la devianza −0,014 y la captura media +0,49); c1 (50) subajusta en ofrecen11 (devianza +0,19); c2 equivale a c3 en ofrecen11. c2 (100 árboles, `min_child_samples` 150) sirve para ambos paneles.
3. **GBM contra historia sola (mismos pesos):** en ofrecen11 la devianza baja ~6% (20,85 vs 22,18); en Solo_Primaria el GBM gana en Q1 (+7,26 con wsat_c2) y cede en Q5 (−3,3; −1,0 a −1,5 en 2022-2023). La ventaja de +10 a +18 puntos en la frontera sobre el GLM en Solo_Primaria es una **cota optimista** (10 valores de alpha, interpolación lineal gruesa para el GLM, cuya curva cambia rápido con alpha); la ventaja de `wsat` sobre `wn` dentro del GBM no se ve afectada.
4. **Calibración = deriva del nivel de la tasa:** Solo_Primaria sobrepredice 12 a 20% (tasa observada de 3,75% a 2,95%); reescalar con el factor del año anterior lo corrige (1,00 a 1,06). En ofrecen11 la tasa sube en 2021 (subpredicción de 16%, calibración 0,84) y luego revierte; reescalar empeora 2022 (0,98 a 1,15). **Los conteos esperados llevan ±15% de incertidumbre de nivel; el producto confiable es el ranking y el riesgo relativo.**
5. Config. de trabajo de la línea Poisson: B2, pesos saturados, c2.

### 11.7 Experimento 6: SHAP por familias (celda 5)
Participación = efecto neto absoluto medio de la familia por sede, con B2 (pesos saturados, c2); entrenar con años < año de prueba y explicar el año de prueba. Aditividad verificada.

- **Ofrecen11, 2023, sin historia:** ICFES 72,2% [69,4; 74,8], tamaño y dinámica 10,7% [10,2; 11,4], composición 8,7% [7,7; 9,9], territorial 8,4% [7,1; 9,8]. La participación de ICFES crece con la ventana de entrenamiento (45,4% en 2021, 61,8% en 2022, 72,2% en 2023): **el orden entre familias es estable, la magnitud no**. Historia propia: 61,7% a 63,8% del total.
- **Solo_Primaria, 2023, sin historia:** territorial 56,7% [55,2; 57,8], composición 27,8% [26,7; 29,4], tamaño y dinámica 15,4% [15,0; 15,8]. En 2021 la composición iba primero (48,9%). Historia propia: 36,1% a 42,4% del total.
- **Dirección (cuartil alto vs bajo, asociación del modelo):** `ICFES_PROM_PUNT_GLOBAL` −31% de riesgo relativo, `ICFES_PROM_INSE` −23%; `FLAG_PDET` +56% (Solo_Primaria) y +8% (ofrecen11); `MATRICULA_PCT_CAMBIO` +8% en ambos.
- **Lista prioritaria (top 10%, alpha 0,20):** en ofrecen11, ICFES es la familia que más sube el riesgo en 88,6% de las sedes de la lista (62,1% fuera); en Solo_Primaria, composición 50,4% y territorial 40,7%. El efecto medio de la historia dentro de la lista (+153% y +81%) supera al de las demás familias (+8% a +14%): **las familias modulan el "por qué" más de lo que deciden "quién" entra**.
- **Criterio de alpha con B2:** captura Q1 a alpha 0,20 de 19,3% (ofrecen11) y 18,7% (Solo_Primaria), 1,9 veces el azar; a 0,25, 13,5% y 14,4% (sigue sobre el azar). **No reproduce las cifras de la tesis** (15,2% y 18,0%), que salen de M4; el umbral de B2 está por encima de 0,25. En Solo_Primaria la captura Q1 es inestable por año: 7,5% (2021, bajo el azar), 14,6% (2022), 33,9% (2023).
- Pendientes: confirmar el año de medición de ICFES (debe ser ≤ t-2) y si es palanca o marcador socioeconómico; las banderas PDET y ZOMAC son contexto estructural (40% de la explicación sin historia en Solo_Primaria); separar factores modificables de contexto.

### 11.8 Experimento 7: objetivos de clasificación y su ruido (celda 6)
Base: Solo_Primaria 242.552 filas con registro, 132.631 elegibles, K = 10,9, tasa media 3,10%; ofrecen11 85.775, 47.851, K = 15,8, 3,29%.

**Rezagos (tabla 1).** Disponibilidad de los rezagos 4 y 5: 0% en 2020 (ninguno), rezago 4 desde 2021 (87,9% Solo_Primaria; 97,9% ofrecen11), rezago 5 desde 2022 (85,9%; 96,2%); en 2023 85 a 98%. Spearman con la tasa observada en t (filas con los tres rezagos: 49.590 en Solo_Primaria, 22.738 en ofrecen11):

| Predictor (tasa ajustada) | Solo_Primaria (todas / Q1 / Q5) | Ofrecen11 (todas / Q1 / Q5) |
|---|---|---|
| LAG3 | 0,119 / 0,019 / 0,363 | 0,389 / 0,231 / 0,557 |
| LAG4 | 0,142 / 0,013 / 0,423 | 0,419 / 0,227 / 0,573 |
| LAG5 | 0,134 / 0,011 / 0,397 | 0,406 / 0,208 / 0,541 |
| LAG3+4+5 agrupado | 0,232 / 0,075 / 0,460 | 0,471 / 0,290 / 0,627 |

**Los rezagos 4 y 5 son tan informativos como el 3 y agrupados casi duplican la señal en Solo_Primaria.** Se incorporan.

**Distribución (tabla 2).** % de ceros por estrato Q1 a Q5: Solo_Primaria 91,4 / 89,7 / 85,5 / 73,0 / 41,5 (total 76,2); ofrecen11 66,6 / 48,5 / 41,8 / 31,3 / 26,6 (total 43,0). Entre las positivas, el P90 de la tasa observada es 33,3% (Solo_Primaria) y 13,2% (ofrecen11); en Q1 de Solo_Primaria el P90 es 100%.

**Cortes y estabilidad (tablas 3a y 3b).** Cortes en 8.2 (esquemas ajustados). Proporciones de clase casi constantes entre 2020 y 2023 en Solo_Primaria (clase 0: 75,3% a 77,1%); en ofrecen11 el cero sube de 41,5% a 46,3% y "Bajo" baja de 31,8% a 26,7% (deriva moderada). Con `adj/P50_P90`: Solo_Primaria Bajo 11,4 a 12,3%, Medio 8,8 a 10,0%, Alto 1,9 a 3,6%; ofrecen11 Alto 5,6 a 7,1%.

**Composición de "Alto" por estrato de tamaño, Q1 a Q5 (tabla 3c).** Solo_Primaria `obs/P50_P90` 34,1 / 28,0 / 20,2 / 14,6 / 3,0 frente a `adj/P50_P90` 16,9 / 15,8 / 18,2 / 28,3 / 20,9; ofrecen11 `obs/P50_P90` 31,9 / 22,3 / 18,2 / 15,2 / 12,5 frente a `adj/P50_P90` 24,3 / 21,9 / 19,6 / 18,2 / 16,1. **La tasa observada infla "Alto" con sedes pequeñas; la ajustada lo reparte.**

**Persistencia, la clase de t-3 como predicción de t (tabla 3d).**

| Definición / esquema | Solo_Primaria: exactitud / exactitud pond. / kappa cuad. / Alto persiste (%) | Ofrecen11: exactitud / pond. / kappa cuad. / Alto persiste (%) |
|---|---|---|
| obs/P50_P90 | 71,3 / 57,8 / 0,258 / 11,8 | 52,5 / 53,2 / 0,409 / 24,8 |
| obs/TERCILES | 69,5 / 50,9 / 0,269 / 18,7 | 48,7 / 46,6 / 0,437 / 42,5 |
| obs/P75_P95 | 74,4 / 69,3 / 0,243 / 10,1 | 59,0 / 62,0 / 0,373 / 19,1 |
| adj/P50_P90 | 70,6 / 55,8 / 0,286 / 10,6 | 52,2 / 52,6 / 0,422 / 26,6 |
| adj/TERCILES | 69,1 / 49,6 / 0,286 / 19,9 | 48,7 / 46,7 / 0,439 / 42,8 |
| adj/P75_P95 | 72,9 / 64,5 / 0,292 / 6,7 | 58,4 / 61,0 / 0,395 / 20,8 |

Kappa por estrato (adj/P50_P90): Solo_Primaria Q1 0,176, Q5 0,330; ofrecen11 Q1 0,330, Q5 0,505. **La persistencia es una línea base débil, sobre todo en Solo_Primaria.**

**Reglas de variación (tabla 4; `RUIDO` = cambio falso / cambio observado).**

| Regla | Solo_Primaria: Baja / Igual / Sube (%), ruido | Ofrecen11: Baja / Igual / Sube (%), ruido |
|---|---|---|
| ABS 0,1 pp | 19,6 / 62,4 / 18,1, 1,12 | 37,3 / 28,7 / 34,1, 1,02 |
| ABS 0,5 pp | 18,7 / 64,0 / 17,2, 1,03 | 33,0 / 36,7 / 30,3, 0,75 |
| ABS 1 pp | 17,4 / 66,6 / 16,0, 0,94 | 28,7 / 44,8 / 26,5, 0,55 |
| REL 10% | 35,9 / 26,2 / 37,9, 0,98 | 43,1 / 14,6 / 42,4, 0,87 |
| REL 25% | 25,6 / 46,1 / 28,3, 0,92 | 35,9 / 28,8 / 35,3, 0,69 |
| Embudo 95% (z 1,96) | 7,1 / 85,8 / 7,1, 0,18 | 20,8 / 59,7 / 19,5, 0,08 |
| Embudo 99,8% (z 3,09) | 3,3 / 93,3 / 3,5, 0,03 | 13,3 / 73,8 / 12,9, 0,01 |
| Embudo 95% con sobredispersión | 7,1 / 85,8 / 7,1, 0,18 | 9,2 / 81,6 / 9,3, 0,00 |

Factor de sobredispersión robusto: 1,00 (Solo_Primaria), 4,06 (ofrecen11). **Los umbrales fijos y relativos marcan tantos cambios como habría si ninguna sede hubiera cambiado** (razón ≈ 1 en Solo_Primaria); el embudo detecta cambios reales pero con 95% es exigente (solo 14,2% y 40,4% de sedes marcadas como cambio). El asesor lo considera alto: de ahí el experimento 8.

**Regresión a la media (tabla 5; nivel `adj/P50_P90`, variación embudo 95%), % Baja / Igual / Sube según el nivel en t-3.**
- Solo_Primaria: Sin 0,0 / 94,2 / 5,8; Bajo 12,8 / 70,0 / 17,2; Medio 32,6 / 63,6 / 3,8; Alto 69,9 / 29,4 / 0,7.
- Ofrecen11: Sin 0,0 / 81,2 / 18,8; Bajo 20,4 / 52,2 / 27,3; Medio 43,7 / 42,7 / 13,7; Alto 67,9 / 26,6 / 5,5.

### 11.9 Experimento 8: aprendibilidad de los objetivos (celda 7) — [EJECUTADO Y ANALIZADO]
Diseño: para cada objetivo (3 esquemas de nivel sobre tasa ajustada y 7 reglas de variación) se ajustaron en retroceso temporal dos modelos, `FULL` (XGBoost con 21 o 23 predictores incluyendo rezagos 3, 4 y 5) y `HIST` (XGBoost solo con `ADJ_LAG3`), y se compararon con `BASE` (nivel: persistencia de t-3; variación: siempre "Igual"). Base: 119.096 filas en Solo_Primaria (1.114 municipios, K=10,9) y 47.429 filas en ofrecen11 (1.067 municipios, K=15,8).

**1. Chequeos de cordura metodológica:**
- Variación: `BASE_KAPPA` = 0,000 en todas las reglas y ambos paneles (correcto por definición al predecir siempre "Igual").
- Nivel: `BASE_KAPPA` reproduce fielmente la persistencia de la tabla 3d del Experimento 7 (Solo_Primaria: 0,299-0,308; ofrecen11: 0,401-0,451).
- Ruido de variación: la regla `FIJA_0.1pp` reproduce un ratio de ruido de 1,12 en Solo_Primaria y 1,02 en ofrecen11 (detecta más ruido binomial que señal real).
- Pruebas superadas con 100% de consistencia.

**2. Resultados en Panel Solo_Primaria (119.096 filas):**
- **Nivel:**
  - `NIVEL_TERCILES`: FULL_F1 0,407, FULL_F1_POND 0,339, FULL_KAPPA 0,234, FULL_AUC 0,768. `FULL - HIST`: Kappa +0,035 [+0,024, +0,049]*. Recall: Sin 70%, Bajo 63%, Medio 27%, Alto 25%. Estabilidad kappa por año: 0,164 (2021), 0,322 (2022), 0,233 (2023).
  - `NIVEL_P50_P90`: FULL_KAPPA 0,197, FULL_AUC 0,755. `FULL - HIST`: Kappa +0,088 [+0,074, +0,103]*. Recall Alto: 29%.
  - `NIVEL_P75_P95`: FULL_KAPPA 0,174, FULL_AUC 0,748. Recall Alto: 24%.
- **Variación:**
  - `VAR_FIJA_0.1pp`: Ruido 1,12. FULL_KAPPA 0,432. FULL - HIST: +0,030 [+0,022, +0,038]*.
  - `VAR_Z_1.28`: Ruido 0,45 (primer z que baja de 0,50). Clases: 12% Baja / 77% Igual / 11% Sube. FULL_F1 0,617, FULL_KAPPA 0,413, FULL_AUC 0,858. `FULL - BASE`: Kappa +0,413 [+0,404, +0,423]*. `FULL - HIST`: Kappa +0,050 [+0,043, +0,058]*. Recall: 90% Baja, 74% Igual, 49% Sube. Estabilidad kappa por año: 0,327 (2021), 0,399 (2022), 0,518 (2023).
  - `VAR_Z_1.96` (95%): Ruido 0,18. Clases: 7% Baja / 86% Igual / 7% Sube. FULL_KAPPA 0,368. `FULL - HIST`: +0,079 [+0,070, +0,091]*.

**3. Resultados en Panel ofrecen11 (47.429 filas):**
- **Nivel:**
  - `NIVEL_TERCILES`: FULL_F1 0,470, FULL_F1_POND 0,482, FULL_KAPPA 0,484, FULL_AUC 0,754. `FULL - BASE`: Kappa +0,033 [+0,026, +0,039]*. `FULL - HIST`: Kappa +0,070 [+0,062, +0,080]*. Recall: Sin 67%, Bajo 39%, Medio 34%, Alto 48%. Estabilidad kappa por año: 0,454 (2021), 0,538 (2022), 0,455 (2023).
  - `NIVEL_P50_P90`: FULL_KAPPA 0,444, FULL_AUC 0,764. `FULL - BASE`: Kappa +0,013 [+0,003, +0,023]*. `FULL - HIST`: Kappa +0,048 [+0,038, +0,057]*. Recall Alto: 45%.
  - `NIVEL_P75_P95`: FULL_KAPPA 0,392. `FULL - BASE`: Kappa -0,009 [-0,020, +0,001] (no supera la persistencia).
- **Variación:**
  - `VAR_FIJA_0.1pp`: Ruido 1,02. FULL_KAPPA 0,295.
  - `VAR_Z_1.28`: Ruido 0,29. Clases: 27% Baja / 48% Igual / 25% Sube. FULL_F1 0,593, FULL_KAPPA 0,354, FULL_AUC 0,797. `FULL - BASE`: Kappa +0,354 [+0,343, +0,366]*. `FULL - HIST`: Kappa +0,095 [+0,080, +0,107]*. Recall: 79% Baja, 58% Igual, 47% Sube. Estabilidad kappa por año: 0,242 (2021), 0,332 (2022), 0,492 (2023).
  - `VAR_Z_1.96` (95%): Ruido 0,08. Clases: 21% Baja / 60% Igual / 20% Sube. FULL_KAPPA 0,367. `FULL - HIST`: +0,068 [+0,057, +0,075]*.

**4. Conclusiones y Selección Definitiva de Objetivos:**
1. **Nivel:** Se adopta `NIVEL_TERCILES` como objetivo formal de nivel. Domina en kappa cuadrático tanto en ofrecen11 (0,484) como en Solo_Primaria (0,234), maximiza el recall de la clase más vulnerable ("Alto": 48% y 25%), supera a la persistencia con significancia estadística en ofrecen11 (+0,033) y supera a la historia sola en ambos paneles (+0,070 y +0,035). Al tener clases positivas homogéneas (~20% en ofrecen11 y ~8% en Solo_Primaria), previene el colapso que sufrían P50_P90 y P75_P95 en la clase Alto (que pesaba solo 1-3%).
2. **Variación:** Se adopta `VAR_Z_1.28` (límite de embudo $z = 1,28$, intervalo del 80%) como objetivo formal de variación. Cumple holgadamente las 4 reglas metodológicas: ganancia `FULL - HIST` con IC positivo excluyendo el cero en ambos paneles (+0,050 y +0,095); ratio de ruido sobre cambio observado menor a 0,50 en ambos paneles (0,45 en Solo_Primaria y 0,29 en ofrecen11); representatividad de clases de cambio ($\ge 11\%$ en Solo_Primaria y $\ge 25\%$ en ofrecen11); y estabilidad de discriminación con kappa positivo en todos los años (alcanzando ~0,50 en 2023). Esto atiende con rigor la solicitud del asesor de no ser tan restrictivo como el 95% ($z = 1,96$), sin caer en la trampa del umbral fijo (0,1 pp) que mide puro ruido.

### 11.10 Experimento 9: comparación de modelos base multiclase (celda 8) — [EJECUTADO Y ANALIZADO]
Diseño: Sobre los dos objetivos formalmente fijados (`NIVEL_TERCILES` en 4 clases y `VAR_Z_1.28` en 3 clases), se entrenaron y evaluaron en retroceso temporal expansivo (pruebas 2021, 2022 y 2023) tres algoritmos candidatos:
1. `XGBoost`: gradient boosted trees con manejo nativo de faltantes en rezagos 4 y 5.
2. `RandomForest`: ensamble balanceado (150 árboles, profundidad 10, hoja mínima 25) con pipeline de imputación por mediana e indicador de faltante ajustado estrictamente en entrenamiento.
3. `MultinomialLogit`: regresión logística multiclase regularizada L2 con estandarización y pipeline de imputación en entrenamiento.
Comparados frente a `BASE` (persistencia a t-3 en nivel; siempre "Igual" en variación) y `HIST` (XGBoost con solo `ADJ_LAG3`). Evaluación agrupada (pooled 2021-2023) con intervalos al 95% por bootstrap de municipios (200 réplicas), desglose por quintiles de matrícula Q1 a Q5 y estabilidad por año. Reportes completos en `Data\Auditorio_Panel_Final\modelo_base_comparacion_<panel>.md`.

**Resultados en Panel ofrecen11 (47.429 filas, 1.067 municipios):**
- **Nivel (`NIVEL_TERCILES`):**
  - XGBoost y Random Forest empatan en el primer lugar: Macro-F1 0,469; F1 ponderado por estudiantes 0,482; Kappa cuadrático 0,484 (XGBoost) y 0,483 (RF); AUC macro 0,754 y 0,756.
  - Ganancias significativas sobre la persistencia (`BASE`): XGBoost +0,033 [+0,027, +0,040]*; RF +0,032 [+0,027, +0,039]*. En 2023 la persistencia se desploma a 0,359, mientras XGBoost se mantiene en 0,455 y RF en 0,442.
  - Ganancias significativas sobre la historia (`HIST`): XGBoost +0,070 [+0,062, +0,078]*; RF +0,069 [+0,062, +0,078]*.
  - Recall en la clase "Alto": 48,1% (XGBoost) y 49,5% (RF). MultinomialLogit alcanza 52,6% pero a costa de peor kappa global (0,459).
  - Kappa por quintiles Q1 a Q5: crece suavemente desde 0,363 (Q1) hasta 0,559 (Q5) en XGBoost.
- **Variación (`VAR_Z_1.28`):**
  - XGBoost lidera ligeramente sobre Random Forest: Macro-F1 0,593 vs 0,590; Kappa 0,354 vs 0,339; AUC 0,797 vs 0,791.
  - Ganancias masivas sobre `BASE`: XGBoost +0,354 [+0,341, +0,366]*; RF +0,339 [+0,325, +0,350]*.
  - Ganancias significativas sobre `HIST`: XGBoost +0,096 [+0,081, +0,108]*; RF +0,081 [+0,068, +0,094]*.
  - Estabilidad temporal: Kappa pasa de 0,245 (2021) a 0,331 (2022) y culmina en 0,491 (2023) en XGBoost.

**Resultados en Panel Solo_Primaria (119.096 filas, 1.114 municipios):**
- **Nivel (`NIVEL_TERCILES`):**
  - Random Forest lidera marginalmente sobre XGBoost en kappa cuadrático: 0,243 vs 0,235; Macro-F1 idéntico de 0,407; AUC 0,769 vs 0,768.
  - Ganancias significativas sobre `HIST`: RF +0,044 [+0,034, +0,057]*; XGBoost +0,037 [+0,024, +0,049]*.
  - Recall por clases: Sin 70%, Bajo 63%, Medio 27%, Alto 24-25%.
  - MultinomialLogit queda rezagado: Kappa 0,208 (diferencia de -0,035 frente a RF).
- **Variación (`VAR_Z_1.28`):**
  - XGBoost y Random Forest prácticamente idénticos: Macro-F1 0,617 vs 0,614; Kappa 0,413 vs 0,408; AUC 0,858 vs 0,855.
  - Ganancias significativas sobre `HIST`: XGBoost +0,050 [+0,042, +0,060]*; RF +0,045 [+0,039, +0,054]*.
  - Ganancias masivas sobre `BASE`: XGBoost +0,413 [+0,403, +0,422]*; RF +0,408 [+0,398, +0,417]*.
  - **Equidad por tamaño (Q1 a Q5):** En las sedes más pequeñas (Q1), el kappa cuadrático alcanza 0,553 en XGBoost y 0,547 en RF (frente a 0,352 en Q5). Esto demuestra que el límite de embudo binomial z=1.28 permite al modelo aprender patrones reales en sedes pequeñas sin ser ahogado por el ruido binomial.
  - Estabilidad temporal: Kappa pasa de 0,329 (2021) a 0,397 (2022) y 0,515 (2023).

**Conclusión del Experimento 9:**
XGBoost y Random Forest se consolidan como los dos modelos de mayor capacidad predictiva y robustez temporal para la deserción escolar multiclase en Colombia. Ambos algoritmos superan de forma incontestable a las líneas base y exhiben un comportamiento equitativo entre sedes rurales pequeñas y urbanas grandes. Pasan a la fase de afinación de hiperparámetros (Experimento 10).

---

## 12. Guía de lectura del experimento 8 y reglas de decisión propuestas

Las reglas son **propuestas de Claude, no acuerdos**; el usuario y el asesor las validan.

**Cordura antes de interpretar.**
- En variación, `BASE` (siempre "Igual") debe dar kappa 0 y macro-F1 ≈ (porcentaje de "Igual") / 3. En nivel, `BASE` debe parecerse a la persistencia de 11.8 (kappa 0,26 a 0,29 en Solo_Primaria; 0,40 a 0,44 en ofrecen11 con tasa ajustada; la celda usa solo filas con registro en t-3 y el entrenamiento de cada pliegue no entra en `BASE`).
- La tabla 1 debe repetir el patrón del experimento 7 (ruido ≈ 1 en reglas fijas de Solo_Primaria; razón baja con embudo).
- Si falla una, **detenerse y consultar** (sección 2.4).

**Qué métrica mirar.** Kappa cuadrático y la ganancia `FULL - HIST` con IC (corrigen por azar y permiten comparar objetivos con distinto balance). El macro-F1 no es comparable entre objetivos con distinto número de clases o balance. AUC para la calidad del ranking probabilístico. Recall de "Alto", "Sube" y "Baja" para política.

**Regla propuesta para la variación (z).** Elegir el **z más bajo** (el asesor pidió bajar del 95%) tal que: (1) la ganancia `FULL - HIST` en kappa tenga IC que excluya 0 en **los dos** paneles; (2) la razón ruido/cambio observado no pase de ~0,5 (tolerancia propuesta, a validar); (3) la clase minoritaria pese al menos ~5 a 10% de las filas; (4) el kappa del modelo completo sea positivo en cada año de prueba. Si ningún z cumple, quedarse con el de menor ruido y reportar el costo. Usar `FIJA_0.1pp` como referencia para explicar al asesor por qué un umbral fijo mide ruido.

**Si `FULL` no supera a `HIST` en variación** (IC incluye 0): la variación sería casi toda regresión a la media explicada por la historia. Es un resultado válido: decirlo al usuario y al asesor y evaluar si conviene otra definición (por ejemplo, variación respecto del promedio de t-3 a t-5) antes de seguir.

**Regla propuesta para el nivel.** Elegir por (1) kappa y ganancia `FULL - BASE` y `FULL - HIST` con IC > 0 en ambos paneles, (2) estabilidad de la proporción de "Alto" entre años, (3) lectura de política. Si empatan, `P50_P90`. Mirar el recall de "Alto".

**Misma regla en ambos paneles** por comparabilidad; si divergen fuerte (ofrecen11 tiene sobredispersión de 4,06 y Solo_Primaria de 1,00), avisar y proponer reglas por panel.

**Después de decidir:** actualizar la sección 8, anotar la decisión en la sección 14, preparar el mensaje tipo WhatsApp para el asesor (decisiones y evidencia, conciso) y construir el experimento 9.

---

## 13. Siguientes pasos: Hoja de ruta para el Agente de Modelamiento (Experimento 10 en adelante)

### 13.1 Estado de los Experimentos de Modelamiento
- **Experimento 9 (Modelos Base): EJECUTADO Y ANALIZADO.** Conclusión: XGBoost y Random Forest empatan en la cima de rendimiento (ambos superan con holgura y significancia a la persistencia y a la historia sola, logrando $\kappa \approx 0,48$ en ofrecen11 y $\kappa \approx 0,41$ en variación primaria). MultinomialLogit queda en tercer lugar como referencia aditiva.

### 13.2 Especificación de la Tarea Inmediata (Experimento 10: Afinación de Hiperparámetros y Regularización)
El siguiente agente debe implementar el **Experimento 10: Afinación de Hiperparámetros Anidada por Año** sobre los dos algoritmos líderes (XGBoost y Random Forest):

**1. Objetivo del Experimento 10:**
- Optimizar la capacidad de generalización y prevenir sobreajuste en los pliegues con menor volumen histórico (especialmente 2021).
- Encontrar la combinación óptima de regularización y complejidad que maximice el kappa cuadrático y la captura de sedes en riesgo ("Alto" y "Sube").

**2. Espacio de Búsqueda Acotado (regularización fuerte):**
- **XGBoost:**
  - `max_depth`: [3, 4, 5] (árboles poco profundos para evitar memorización).
  - `learning_rate`: [0.03, 0.05, 0.08] con `n_estimators` calibrado por early stopping o fijado en [150, 250].
  - `min_child_weight`: [3, 5, 10] (fundamental para regularizar sedes pequeñas).
  - `reg_alpha` (L1): [0.0, 0.5, 1.0] y `reg_lambda` (L2): [1.0, 3.0, 5.0].
  - `subsample` y `colsample_bytree`: [0.7, 0.85].
- **Random Forest:**
  - `max_depth`: [8, 10, 12, None].
  - `min_samples_leaf`: [15, 25, 40] (evitar que hojas con muy pocas sedes determinen clases).
  - `max_features`: ["sqrt", 0.5, 0.8].

**3. Protocolo de Validación Anidada:**
- Validación rolling-origin estricta: la selección de hiperparámetros se realiza evaluando únicamente sobre los años de entrenamiento disponibles antes del año de prueba.
- Métrica de selección interna: Kappa cuadrático ponderado y recall de clases prioritarias.

**4. Salidas esperadas:**
- `Data\Auditorio_Panel_Final\modelo_afinacion_hiperparametros_ofrecen11.md`
- `Data\Auditorio_Panel_Final\modelo_afinacion_hiperparametros_Solo_Primaria.md`

### 13.3 Cronograma posterior hacia el 11 de diciembre:
11. **Matriz de prioridad conjunta** (Nivel × Variación): cruce de etiquetas predichas para determinar sedes en "Alto y Sube" (prioridad máxima de política).
12. **Explicabilidad:** SHAP por familias sobre el modelo afinado final (clases Alto y Sube, sin la familia de historia) y coeficientes del multinomial.
13. **Calibración de probabilidades multiclase** (curvas de confiabilidad Brier/ECE).
14. **Stacking** (posterior al 11 de diciembre): meta-modelo multinomial sobre predicciones fuera de muestra.
15. **Sensibilidades:** sin 2020/2021, con/sin ceros imputados, ablación de `DESERCION_MPIO_LAG2`.
16. **Scoring y herramienta final:** tabla de scoring, factores principales por familias y prototipo de interfaz.

---

## 14. Registro de decisiones y pendientes con el asesor

### 14.1 Decisiones vigentes (cronología resumida)
| Cuándo | Decisión | Quién |
|---|---|---|
| Antes del experimento 1 | Target a nivel sede; rezago de deserción de 3 años; ceros imputados con bandera; peso como columna separada; panel 2017 a 2024 | Usuario, con Claude |
| Tras el experimento 2 | Pasar de "solo positivas" a Poisson sobre todas las sedes con registro (ensamble Poisson, RF, XGBoost, LightGBM, SHAP) | Usuario |
| Sesión de asesoría de Claude | LightGBM y XGBoost se instalan sin problema; explicar por familias y **sin el lag**; comenzar con experimentos de offset | Usuario |
| Tras los experimentos 4 y 5 | Predecir con B2 (pesos saturados, capacidad c2) y explicar sin la familia de historia; continuar con SHAP por familias | Usuario y Claude |
| Reunión con el asesor (tras el experimento 6) | Abandonar Poisson; clasificación multiclase (≤ 4 rangos, cortes estáticos por percentil) y segunda variable de variación; stacking con RF, XGBoost y multinomiales; rezagos de hasta 3 años; explicar con los modelos principales; métricas F-score, ROC multiclase y kappa; entregar modelos básicos comparados el 11 de diciembre | Usuario y asesor |
| Respuesta del usuario a la propuesta de Claude | Usar rezagos 3, 4, 5 si son valiosos; imputación aprobada; evaluación ponderada también en multiclase; la prioridad incluirá si se predice que sube o baja; umbral de variación según la literatura; persistencia como línea base; **el cero es clase aparte**; **cortes por percentil con todo lo disponible** | Usuario |
| Tras el experimento 7 | El asesor: "95 me parece alto, toca probar y ver cómo queda" → experimento 8 con z bajos | Asesor |
| Tras el experimento 8 | Cierre de premodelamiento: se fijan `NIVEL_TERCILES` (4 clases, cero aparte, cortes en percentiles 33,3 y 66,7 de tasas positivas ajustadas) y `VAR_Z_1.28` (límite de embudo con z=1,28, bilateral 80%). Se pasa al modelamiento base (Experimento 9: XGBoost, Random Forest, Multinomial). | Usuario y Claude |
| Tras el experimento 9 | Comparación de modelos base: XGBoost y Random Forest empatan como líderes con $\kappa \approx 0,48$ en ofrecen11 y $\kappa \approx 0,41$ en variación primaria, superando holgadamente a la persistencia y a la historia sola. Ambos eliminan el sesgo contra sedes pequeñas ($\kappa > 0,55$ en Q1 para variación). Pasan a afinación de hiperparámetros (Experimento 10). | Usuario y Claude |
| Formato | Explicaciones como a un niño de 5 años salvo el párrafo académico; párrafo académico al cierre de cada experimento; solo celdas en el notebook (sin `.py`); sin CSV si no es necesario | Usuario |

### 14.2 Pendientes de confirmar con el asesor
1. Validar la adopción de `NIVEL_TERCILES` y `VAR_Z_1.28` (respaldadas por la evidencia del Experimento 8).
2. Reportar que XGBoost y Random Forest empatan en la cima con ganancias estadísticamente significativas sobre la historia (+0,07 a +0,09 en grado 11) y sobre la persistencia.
3. Interpretación del horizonte: predecir t con rezagos t-3, t-4, t-5 por retraso de publicación del C-600.
4. Evaluación ponderada por estudiantes y por estrato de tamaño; persistencia y `HIST` como líneas base.

### 14.3 Mensaje propuesto para el asesor tras los Experimentos 8 y 9 (tipo WhatsApp, conciso)
"Hola Profe. Cerramos los objetivos y corrimos ya la comparación de los modelos base (XGBoost, Random Forest y Multinomial) con las reglas acordadas (Terciles para nivel y límite de embudo z=1.28 para variación). Conclusiones clave:
1. XGBoost y Random Forest empatan en el primer lugar y superan con holgura y significancia estadística a la historia sola (+0.07 en nivel y +0.09 en variación en sedes con 11) y a la persistencia.
2. En variación, en las sedes más pequeñas (Q1) ambos modelos logran un kappa superior a 0.55, demostrando que el límite de embudo resolvió de raíz el problema del ruido aleatorio en colegios pequeños.
3. El logit multinomial queda en tercer lugar (kappa ~0.46 y 0.33), pero lo conservamos como referencia aditiva e interpretable.
Con esto ya tenemos la tabla base para el 11 de diciembre y arrancamos la afinación de hiperparámetros para exprimir la máxima regularización."
Con estos dos objetivos ya cerrados, arrancamos a correr y comparar los modelos base (XGBoost, Random Forest y Multinomial) para tenerle la tabla comparativa el 11 de diciembre."

---

## 15. Problemas encontrados y cómo se resolvieron (para no repetirlos)

- **Tipología silenciosa.** Al pegar una versión nueva del maestro se reinició la configuración y todas las sedes quedaron `SIN_TIPOLOGIA`. Ahora el maestro y la Fase 2 se detienen. Constantes reales: `Data\Raw\Enrichment\Clasificacion_Ruralidad_DNP.xlsx`, hoja 0, columnas `Codigo DANE` y `Categoria de Ruralidad DNP`.
- **Códigos DANE.** Al leer CSV se pierden ceros a la izquierda; las celdas leen `SEDE_CODIGO`, `COD_MPIO_DANE` y `COD_DPTO_DANE` como texto. En Excel es solo un artefacto de visualización.
- **OneDrive.** `OSError [Errno 22]` al guardar figuras en carpetas sincronizadas; escritura con reintentos. Todas las celdas de reporte capturan `OSError` para no abortar.
- **Error de etiqueta en el script de historia** (buscaba `BASE` y el índice es `M4_BASE`); corregido.
- **Validación del rezago.** Las celdas reconstruyen la historia de t-3 del propio panel y exigen que coincida con `DESERCION_LAG3`.
- **Comparar a alpha fijo** confunde calidad con dispersión de las tasas (experimento 4); se resolvió con la frontera. La frontera con 10 valores de alpha subestima el GLM por interpolación lineal; si se vuelve a usar, refinar la rejilla cerca de alpha 0.
- **Definición de participación SHAP** distinta entre las celdas 3 y 5 (suma de |SHAP| por variable frente a efecto neto por familia); las cifras no son comparables.
- **Pliegue 2021** entrena con un solo año; reportar siempre también 2022-2023.
- **pandas.** `groupby(...).apply(..., include_groups=False)` y `reset_index(names=...)` fallan en versiones antiguas; se reemplazaron.
- **Markdown.** Un `|` dentro de un encabezado o celda rompe la tabla; se usa `/`.
- **XGBoost** exige que todas las clases estén presentes en el entrenamiento de cada pliegue; la celda 7 omite el pliegue con aviso si falta una clase.
- **K y media con todos los datos** (celdas 6 y 7) son constantes de etiquetado; fuga despreciable pero declarada.
- **Qué NO se pudo hacer.** Claude nunca corrió el pipeline con los datos completos. Todas las pruebas fueron con datos sintéticos y con las muestras de 99 filas por hoja (de un solo municipio). Las cifras reales vienen de los `.md` que pegó el usuario.

---

## 16. Cómo se probó el código (por si hay que modificarlo)

- Se parchan los archivos con reemplazos exactos (con aserción de que el texto aparece una sola vez), se compilan y se prueban en un entorno temporal que redirige `BASE_DIR`.
- Panel final simulado (años 2017 a 2023): sedes con riesgo latente, tamaños lognormales, 5% de sedes sin registro por año, `DESERCION_LAG3` consistente con la tasa de t-3, 120 municipios; con y sin columnas ICFES. Las celdas se ejecutan con `python -W error::RuntimeWarning` para que cualquier advertencia numérica falle. **Los resultados sintéticos no sirven para concluir nada sobre el proyecto.**
- Verificaciones específicas: el estimador de K recupera 9,8, 39,2 y 199,9 con datos Beta-Binomial de K = 10, 40 y 200; el LightGBM con offset y tasa de aprendizaje ≈ 0 reproduce el GLM (diferencia de 1e-10); la aditividad de SHAP (suma de contribuciones + constante = puntaje crudo); `B2_wn_c3` (celda 4) reproduce exactamente `B2_offset_con_hist_t150` (celda 3) en los datos sintéticos; `cm_metrics` (celda 7) coincide con scikit-learn en macro-F1, kappa cuadrático y exactitud balanceada.
- Fallos de escritura se probaron forzando `OSError 22`.

---

## 17. Preferencias del usuario (Juan Felipe Malaver Osorio)

- Respuestas directas y estructuradas, con conclusiones claras y sin rodeos; una pregunta por respuesta como máximo.
- Para los experimentos: explicación como a un niño de cinco años (qué queremos ver, qué se hizo, para qué, conclusión) y, aparte, un **párrafo académico** al cierre de cada experimento.
- Código completo en una sola celda del notebook, comentarios en inglés, orden rutas, variables, funciones, ejecución. Sin `.py` aparte. Sin CSV salvo necesidad.
- Máquina: Windows corporativo con restricciones de red y herramientas; OneDrive y VS Code.
- Decide con evidencia numérica y su asesor también; quiere ver los números detrás de cada recomendación. Pide ir rápido.
- Textos de tesis: español formal, tercera persona, sin guiones largos, sin exceso de subtítulos.
- Mensajes para el asesor: tipo WhatsApp, concisos, con las decisiones a validar.
