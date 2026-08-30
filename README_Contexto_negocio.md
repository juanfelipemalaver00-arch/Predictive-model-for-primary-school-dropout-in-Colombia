# Estructura del Proyecto — Deserción Escolar Temprana Colombia

> **Maestría en Business Analytics** · Universidad del Rosario  
> Autor: Juan Felipe Malaver   
> Metodología: CRISP-DM · Periodo: 2018–2022

---

## 1. Por qué hacemos lo que hacemos

Colombia tiene una tasa de deserción escolar intra-anual que a nivel nacional ronda el 3–5% en el sector oficial, pero con variaciones territoriales extremas: municipios rurales, zonas de conflicto o con alta dispersión geográfica pueden superar el 20%. Cuando un estudiante abandona el sistema escolar durante el año, las Secretarías de Educación usualmente se enteran tarde, cuando la intervención ya no es posible, resultando en perdidas billonarias para el estado colombiano por mala asignación de recursos y miles de jovenes que seguiran dentro de la trampa de pobreza y no podran desarrollar todo su potencial para aportar a la sociedad en el futuro 

El problema no es la falta de datos — el Estado colombiano registra matrícula, jornadas, niveles y poblaciones especiales a nivel de sede desde hace años a través del C-600 y el SIMAT. El problema es que esa información nunca se ha integrado en un sistema que permita **anticipar** el riesgo antes de que ocurra el abandono.

Este proyecto construye ese sistema. El producto final es un **modelo de alerta temprana** que predice qué sedes educativas tienen mayor probabilidad de registrar deserción elevada el siguiente año, y por qué, permitiendo a las 97 Secretarías de Educación certificadas del país focalizar intervenciones de forma proactiva y eficiente permitiendo tanto predecir la deserción escolar como dar una recomendación de negocio para intervenir esa sede.

Las tres preguntas que guían el trabajo son:

1. ¿Qué sedes tienen mayor riesgo de deserción el próximo año?
2. ¿Qué factores explican ese riesgo y en qué magnitud?
3. ¿El modelo consolidado es igualmente preciso para sedes con poblaciones vulnerables (víctimas del conflicto, grupos étnicos, estudiantes con discapacidad)?

---

## 2. Variable objetivo y qué queremos lograr

| Dimensión | Decisión |
|---|---|
| **Unidad de análisis** | Sede educativa × año (`SEDE_CODIGO` × `PERIODO_ANIO`) |
| **Variable objetivo** | Tasa de deserción intra-anual municipal imputada a cada sede |
| **Tipo de problema** | Clasificación binaria (alto / bajo riesgo) — umbral a definir con el asesor |
| **Ventana de entrenamiento** | 2018–2022 |
| **Validación out-of-time** | 2023–2024 (datos reservados, no tocar hasta evaluación final) |
| **Algoritmos candidatos** | Regresión Logística (baseline) · Random Forest · XGBoost/LightGBM |

La variable objetivo no existe directamente a nivel de sede: el SIMAT publica deserción solo a nivel municipal. La estrategia es **imputación por homoscedasticia**: asignar la tasa municipal a todas las sedes del mismo municipio y año, asumiendo que las condiciones del municipio afectan por igual a sus sedes. Este supuesto se documenta como limitación en la tesis.

Lo que queremos lograr al final no es solo un número de AUC: es un **ranking accionable de sedes por riesgo** que un funcionario de una Secretaría pueda leer, entender y usar para decidir dónde intervenir primero, con una explicación en lenguaje natural de por qué esa sede está en riesgo.

---

## 3. De dónde salen los datos

### Estructura de carpetas

```
Data/
├── Raw/                          # Datos originales — nunca editar directamente
│   ├── C-600/                    # Censo de Educación Formal (DANE) — nivel sede
│   │   ├── 2018/
│   │   │   ├── Desplazados_2018.csv
│   │   │   ├── Limitacion_fisica_2018.csv
│   │   │   ├── Ed_tradicional_2018.csv
│   │   │   ├── Ed_Flexible_2018.csv
│   │   │   ├── Jornadas_nivel_2018.csv
│   │   │   └── Etnia_2018.csv
│   │   ├── 2019/ … 2022/         # misma estructura por año
│   ├── SIMAT/                    # Tasas municipales (MEN)
│   │   ├── Tasa_Desercion_intra_Departamentos.xlsx
│   │   ├── Tasa_repitencia_intra_Departamentos.xlsx
│   │   └── DIVIPOLA.csv          # Tabla nombre municipio → código DANE
│   ├── IPM/                      # Pobreza multidimensional (DANE-ECV)
│   │   ├── IPM_Hogares_2018.csv
│   │   ├── IPM_Hogares_2019.csv
│   │   ├── IPM_Hogares_2020.csv
│   │   ├── IPM_Hogares_2021.csv
│   │   └── IPM_Hogares_2022.csv
│   └── Enrichment/               # Fuentes territoriales adicionales — todos los años disponibles
│       ├── Icfes_Resumen.csv             #  listo — nivel sede × año
│       ├── PDET_municipios.xlsx          #  listo — 170 municipios con COD DANE
│       ├── ZOMAC_municipios.xlsx         #  listo — 344 municipios con COD DANE
│       ├── Terridata_completo.csv        #  listo — panel municipal multi-indicador (DNP)
│       └── Distancia_capital_mpio.csv    #  pendiente desde los crudos — se calcula con GeoPandas
├── Processed/                    # Outputs del pipeline (generados por código)
│   ├── panel_maestro.parquet
│   ├── panel_maestro.csv
│   └── diagnostico_panel.xlsx
└── External/
    └── DIVIPOLA_referencia.csv
```

---

### Fuente 1 — C-600 DANE (nivel sede)

**Qué es:** El formulario C-600 (Encuesta de Educación Formal) es el censo anual de matrícula que el DANE levanta en todas las sedes del país. Es la fuente más granular del proyecto y el origen de los predictores principales del modelo.

**Cómo se descargó:** Portal de microdatos del DANE. Encoding `latin1`, separador coma.

**Nota técnica crítica:** `SEDE_CODIGO` llega en notación científica desde Excel (ej. `2.05212E+11`). Siempre leer como `string` y rellenar a 12 dígitos con `zfill(12)`. Los primeros 5 dígitos son el código DANE del municipio — llave de cruce con el SIMAT.

| Archivo | Población que describe | Columnas de conteo |
|---|---|---|
| `Desplazados_YYYY.csv` | Alumnos víctimas del conflicto armado | `JORNDES_CANTIDAD_HOMBRE/MUJER` |
| `Limitacion_fisica_YYYY.csv` | Alumnos con discapacidad | `JORNLIM_CANTIDAD_HOMBRE/MUJER` |
| `Ed_tradicional_YYYY.csv` | Matrícula en aulas regulares por grado y edad | `JORNTRA_CANTIDAD_HOMBRE/MUJER` |
| `Ed_Flexible_YYYY.csv` | Matrícula en modelos flexibles (Escuela Nueva, CLEI…) | `JORNMOD_CANTIDAD_HOMBRE/MUJER` |
| `Jornadas_nivel_YYYY.csv` | **Total de alumnos por sede** — esqueleto del panel | `SEDEALUM_CANTIDAD` |
| `Etnia_YYYY.csv` | Alumnos pertenecientes a grupos étnicos | `JORNETN_CANTIDAD_HOMBRE/MUJER` |

Todos comparten las columnas: `SEDE_CODIGO`, `PERIODO_ANIO`, `JORNADA_NOMBRE`, `NIVELENSE_NOMBRE`, más columnas técnicas con IDs redundantes (`_ID`, `_CODIGO`) que no se usan en el modelo.

---

### Fuente 2 — SIMAT MEN (nivel municipal)

**Qué es:** Tasas de deserción y repitencia intra-anual del MEN. El proyecto usa exclusivamente `TERRITORIO = MUNICIPIO` y `SECTOR = Oficial`. Un archivo Excel por indicador con todos los años (2015–2024).

**Cómo se descargó:** Portal BI del MEN, indicador 22.

| Archivo | Variable | Columnas clave |
|---|---|---|
| `Tasa_Desercion_intra_Departamentos.xlsx` | Tasa de deserción | `AÑO`, `MUNICIPIO`, `DEPARTAMENTO`, `SECTOR`, `NIVEL EDUCATIVO`, `DESERTORES`, `TOTAL`, `TASA` |
| `Tasa_repitencia_intra_Departamentos.xlsx` | Tasa de repitencia | Igual, `DESERTORES` → `REPITENTES` |

`TASA` es `NaN` cuando `TOTAL = 0`: indefinición matemática, no dato faltante. Se filtra antes de modelar.

---

### Fuente 3 — IPM DANE (nivel hogar, agregable a región)

**Qué es:** Microdatos de la Encuesta Nacional de Calidad de Vida (ECV) para el cálculo del IPM. Un archivo por año (2018–2022), separador punto y coma.

**Restricción:** La única variable geográfica es `region` (9 regiones DANE). Se incorpora al panel como contexto regional, no municipal.

| Variable | Descripción |
|---|---|
| `ipm` | Índice del hogar (0–1). Pobre si ≥ 0.333 |
| `inasistencia_escolar` | Privación por inasistencia — directamente relacionada con deserción |
| `rezago_escolar` | Privación por rezago — predictor documentado de deserción |
| `trabajo_infantil` | Factor de riesgo de abandono escolar |
| `fex_c` | Factor de expansión por hogar |
| `region` | 1=Caribe · 2=Oriental · 3=Central · 4=Bogotá · 5=Antioquia · 6=Valle · 7=Pacífica · 8=Orinoquía-Amazonía · 9=San Andrés |

---

### Fuente 4 — Enriquecimiento territorial (pendiente de descarga)

Variables solicitadas por el asesor. Todas se cruzan por `cod_mpio_dane` (código DANE de 5 dígitos).

| Variable | Archivo | Fuente | Llave de cruce | Estado |
|---|---|---|---|---|
| Resultados ICFES Saber 11° por sede | `Icfes_Resumen.csv` | DataIcfes | `cole_cod_dane_sede` × `anio` | ✅ |
| Clasificación PDET (170 municipios) | `PDET_municipios.xlsx` | ART | `COD DANE` (5 dígitos) | ✅ |
| Clasificación ZOMAC (344 municipios) | `ZOMAC_municipios.xlsx` | DIAN | `COD DANE` (5 dígitos) | ✅ |
| PIB, población y otros indicadores municipales | `Terridata_completo.csv` | DNP Terridata | `Codigo_Entidad` × `Anio` | ✅ |
| Distancia a capital departamental (km) | `Distancia_capital_mpio.csv` | Shapefile MGNCNPV — DANE | `cod_mpio_dane` | ⏳ |

**Variables del ICFES agregadas por sede y año:**

| Variable | Descripción |
|---|---|
| `cole_cod_dane_sede` | Código DANE de la sede — llave directa de cruce con `SEDE_CODIGO` del C-600 |
| `cant_estudiantes` | Número de estudiantes que presentaron Saber 11° en esa sede y año |
| `prom_punt_global` | Puntaje global promedio (proxy de calidad académica de la sede) |
| `pct_desplazacolegio` | % de estudiantes que se desplazan para llegar al colegio |
| `pct_horastrabnoremu` | % de estudiantes con horas de trabajo no remunerado (proxy de trabajo infantil) |
| `pct_fami_tieneinternet` | % de familias con acceso a internet (proxy de conectividad y NSE) |
