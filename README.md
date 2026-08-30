# Project Structure — Early School Dropout in Colombia

> **Master’s in Business Analytics** · Universidad del Rosario  
> Author: Juan Felipe Malaver  
> Methodology: CRISP-DM · Period: 2018–2022

---

## 1. Problem Statement & Motivation

In Colombia, the intra-annual school dropout rate in the public sector averages between 3% and 5% nationally. However, regional disparities are extreme: rural municipalities, conflict zones, or areas with high geographical dispersion can experience dropout rates exceeding 20%. When students leave the school system mid-year, Secretariats of Education usually find out too late to intervene. This results in billions of pesos in lost public funds due to misallocated resources and leaves thousands of young people trapped in poverty, unable to reach their full potential or contribute to society.

The issue is not a lack of data. The Colombian government has systematically recorded campus-level enrollment, schedules, educational levels, and special populations for years through the C-600 census and the SIMAT system. The real problem is that this information has never been integrated into a system capable of **anticipating** dropout risk before abandonment occurs.

This project builds that predictive system. The final product is an **early warning model** that predicts which educational sites are at high risk of elevated dropout rates in the following year and identifies the underlying causes. This tool enables Colombia’s 97 Certified Secretariats of Education to target proactive interventions efficiently, combining predictive risk scoring with actionable, data-driven recommendations for site-level intervention.

The three core research questions guiding this project are:

1. Which educational sites face the highest risk of student dropout next year?
2. Which factors explain this risk, and to what extent?
3. Is the consolidated model equally accurate for school sites serving vulnerable populations (victims of armed conflict, ethnic minorities, students with disabilities)?

---

## 2. Target Variable & Project Scope

| Dimension | Decision |
|---|---|
| **Unit of Analysis** | Educational site × year (`SEDE_CODIGO` × `PERIODO_ANIO`) |
| **Target Variable** | Municipal intra-annual dropout rate imputed to each school site |
| **Problem Type** | Binary classification (High / Low Risk) — threshold to be defined with the advisor |
| **Training Window** | 2018–2022 |
| **Out-of-Time Validation** | 2023–2024 (holdout dataset, untouched until final evaluation) |
| **Candidate Algorithms** | Logistic Regression (baseline) · Random Forest · XGBoost / LightGBM |

The target variable is not directly available at the site level, as SIMAT only publishes dropout rates aggregated at the municipal level. To address this, the project applies **homoscedastic imputation**: assigning the municipal rate to all educational sites within the same municipality and year, assuming municipal-level conditions impact all local sites uniformly. This assumption is documented as a project limitation.

The ultimate goal goes beyond optimizing predictive metrics like AUC; it aims to generate an **actionable site risk ranking**. Education officials can easily interpret this ranking to prioritize interventions, supported by natural language explanations detailing why a specific site is at risk.

---

## 3. Data Architecture & Sources

### Folder Structure

```
Data/
├── Raw/                                # Original raw data — never edit directly
│   ├── C-600/                          # Formal Education Census (DANE) — site level
│   │   ├── 2018/
│   │   │   ├── Desplazados_2018.csv
│   │   │   ├── Limitacion_fisica_2018.csv
│   │   │   ├── Ed_tradicional_2018.csv
│   │   │   ├── Ed_Flexible_2018.csv
│   │   │   ├── Jornadas_nivel_2018.csv
│   │   │   └── Etnia_2018.csv
│   │   ├── 2019/ … 2022/              # Same annual directory structure
│   ├── SIMAT/                          # Municipal rates (MEN)
│   │   ├── Tasa_Desercion_intra_Departamentos.xlsx
│   │   ├── Tasa_repitencia_intra_Departamentos.xlsx
│   │   └── DIVIPOLA.csv               # Lookup table: Municipality name → DANE code
│   ├── IPM/                            # Multidimensional Poverty Index (DANE-ECV)
│   │   ├── IPM_Hogares_2018.csv
│   │   ├── IPM_Hogares_2019.csv
│   │   ├── IPM_Hogares_2020.csv
│   │   ├── IPM_Hogares_2021.csv
│   │   └── IPM_Hogares_2022.csv
│   └── Enrichment/                     # Additional territorial features — all available years
│       ├── Icfes_Resumen.csv           # Ready — site level × year
│       ├── PDET_municipios.xlsx        # Ready — 170 municipalities with DANE code
│       ├── ZOMAC_municipios.xlsx       # Ready — 344 municipalities with DANE code
│       ├── Terridata_completo.csv      # Ready — multi-indicator municipal panel (DNP)
│       └── Distancia_capital_mpio.csv  # Pending extraction from raw files via GeoPandas
├── Processed/                          # Pipeline outputs (generated programmatically)
│   ├── panel_maestro.parquet
│   ├── panel_maestro.csv
│   └── diagnostico_panel.xlsx
└── External/
    └── DIVIPOLA_referencia.csv
```

---

### Source 1 — DANE C-600 Census (Site Level)

**Description:** The C-600 form (Formal Education Survey) is DANE's annual enrollment census covering every educational site in Colombia. It serves as the primary predictor source and the most granular dataset in this project.

**Extraction Method:** Downloaded from DANE's microdata portal (`latin1` encoding, comma-separated).

**Critical Technical Note:** `SEDE_CODIGO` is often parsed in scientific notation by Excel (e.g., `2.05212E+11`). It must always be imported as a string and zero-padded to 12 digits using `zfill(12)`. The first 5 digits represent the municipal DANE code, which serves as the merge key for SIMAT datasets.

| File | Target Population | Count Columns |
|---|---|---|
| `Desplazados_YYYY.csv` | Students impacted by armed conflict | `JORNDES_CANTIDAD_HOMBRE/MUJER` |
| `Limitacion_fisica_YYYY.csv` | Students with physical or cognitive disabilities | `JORNLIM_CANTIDAD_HOMBRE/MUJER` |
| `Ed_tradicional_YYYY.csv` | Regular classroom enrollment by grade and age | `JORNTRA_CANTIDAD_HOMBRE/MUJER` |
| `Ed_Flexible_YYYY.csv` | Enrollment in flexible education models (Escuela Nueva, CLEI, etc.) | `JORNMOD_CANTIDAD_HOMBRE/MUJER` |
| `Jornadas_nivel_YYYY.csv` | **Total student count per site** — core panel backbone | `SEDEALUM_CANTIDAD` |
| `Etnia_YYYY.csv` | Students belonging to recognized ethnic groups | `JORNETN_CANTIDAD_HOMBRE/MUJER` |

All files share the key identifiers: `SEDE_CODIGO`, `PERIODO_ANIO`, `JORNADA_NOMBRE`, and `NIVELENSE_NOMBRE`. Technical columns containing redundant identifiers (`_ID`, `_CODIGO`) are removed prior to modeling.

---

### Source 2 — MEN SIMAT System (Municipal Level)

**Description:** Contains intra-annual dropout and grade repetition rates published by the Ministry of National Education (MEN). The pipeline filters exclusively for `TERRITORIO = MUNICIPIO` and `SECTOR = Oficial`. Includes one Excel file per indicator covering 2015–2024.

**Extraction Method:** Extracted from the MEN Business Intelligence portal (Indicator 22).

| File | Target Variable | Key Columns |
|---|---|---|
| `Tasa_Desercion_intra_Departamentos.xlsx` | Intra-annual dropout rate | `AÑO`, `MUNICIPIO`, `DEPARTAMENTO`, `SECTOR`, `NIVEL EDUCATIVO`, `DESERTORES`, `TOTAL`, `TASA` |
| `Tasa_repitencia_intra_Departamentos.xlsx` | Intra-annual repetition rate | Identical structure (`DESERTORES` replaced by `REPITENTES`) |

`TASA` evaluates to `NaN` when `TOTAL = 0` due to mathematical division by zero rather than missing data. These instances are filtered out prior to training.

---

### Source 3 — DANE Multidimensional Poverty Index (Household / Regional Level)

**Description:** Microdata from the Quality of Life Survey (ECV) used to compute the Multidimensional Poverty Index (IPM). Contains annual semicolon-separated files from 2018 to 2022.

**Geographic Constraint:** The finest geographic granularity available is `region` (9 DANE macro-regions). It is integrated into the master panel as regional context rather than municipal-level data.

| Variable | Description |
|---|---|
| `ipm` | Household poverty index (0–1). Classified as poor if ≥ 0.333 |
| `inasistencia_escolar` | Deprivation due to school non-attendance — directly correlated with dropout rates |
| `rezago_escolar` | Deprivation due to educational lag — a documented dropout predictor |
| `trabajo_infantil` | Child labor deprivation — major risk factor for school abandonment |
| `fex_c` | Household sampling weight factor |
| `region` | 1=Caribbean · 2=Eastern · 3=Central · 4=Bogotá · 5=Antioquia · 6=Valle · 7=Pacific · 8=Orinoquía-Amazonía · 9=San Andrés |

---

### Source 4 — Territorial Context & Enrichment Features

External datasets integrated via `cod_mpio_dane` (5-digit municipal DANE code).

| Variable | File | Source | Join Key | Status |
|---|---|---|---|---|
| ICFES Saber 11° exam results by site | `Icfes_Resumen.csv` | DataIcfes | `cole_cod_dane_sede` × `anio` | ✅ Ready |
| PDET status (170 priority municipalities) | `PDET_municipios.xlsx` | ART | `COD DANE` (5 digits) | ✅ Ready |
| ZOMAC status (344 conflict-affected areas) | `ZOMAC_municipios.xlsx` | DIAN | `COD DANE` (5 digits) | ✅ Ready |
| Municipal GDP, population & socio-demographics | `Terridata_completo.csv` | DNP Terridata | `Codigo_Entidad` × `Anio` | ✅ Ready |
| Distance to departmental capital (km) | `Distancia_capital_mpio.csv` | DANE MGNCNPV Shapefile | `cod_mpio_dane` | ⏳ Pending |

**ICFES Variables Aggregated by Educational Site & Year:**

| Variable | Description |
|---|---|
| `cole_cod_dane_sede` | Educational site DANE code — direct join key with C-600 `SEDE_CODIGO` |
| `cant_estudiantes` | Number of students taking the Saber 11° exam at that site in a given year |
| `prom_punt_global` | Mean overall test score (proxy for academic quality) |
| `pct_desplazacolegio` | % of students commuting to reach their school campus |
| `pct_horastrabnoremu` | % of students working unpaid hours (proxy for child labor) |
| `pct_fami_tieneinternet` | % of households with internet access (proxy for digital connectivity and SES) |