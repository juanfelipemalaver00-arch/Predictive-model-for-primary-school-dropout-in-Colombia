# Project Structure — Early School Dropout in Colombia

> **Master’s in Business Analytics** · Universidad del Rosario  
> Author: Juan Felipe Malaver  
> Methodology: CRISP-DM · Period: 2018–2023

---

## 1. Problem Statement & Motivation

In Colombia, the intra-annual school dropout rate in the public sector averages between 3% and 5% nationally. However, regional disparities are extreme: rural municipalities, conflict zones, or areas with high geographical dispersion can experience dropout rates exceeding 20%. When students leave the school system mid-year, Secretariats of Education usually find out too late to intervene. This results in lost public funds due to misallocated resources and leaves thousands of young people trapped in poverty, unable to reach their full potential or contribute to society.

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
| **Target Variable** | Municipal intra-annual dropout rate imputed to each school site (`TASA_DESERCION_MPIO`) |
| **Problem Type** | Binary classification (High / Low Risk) — threshold defined with advisor |
| **Training Window** | 2018–2023 |
| **Out-of-Time Validation** | 2024 (holdout dataset, pending publication by SINEB/ICFES) |
| **Candidate Algorithms** | Logistic Regression (baseline) · Random Forest · XGBoost / LightGBM |
| **Feature Space** | 70 variables structured across 8 thematic domains |

The target variable is not directly available at the site level, as SIMAT only publishes dropout rates aggregated at the municipal level. To address this, the project applies **homoscedastic imputation**: assigning the municipal rate to all educational sites within the same municipality and year, assuming municipal-level conditions impact all local sites uniformly. This assumption is documented as a project limitation[cite: 1].

The ultimate goal goes beyond optimizing predictive metrics like AUC; it aims to generate an **actionable site risk ranking**[cite: 1]. Education officials can easily interpret this ranking to prioritize interventions, supported by natural language explanations detailing why a specific site is at risk[cite: 1].

---

## 3. Data Architecture & Sources

### Folder Structure

Data/
├── Raw/                                # Original raw data — never edit directly[cite: 1]
│   ├── C-600/                          # Formal Education Census (DANE) — site level[cite: 1]
│   │   ├── 2018/ … 2023/               # Annual directory structure (2018–2023)[cite: 1]
│   │   │   ├── Desplazados_YYYY.csv[cite: 1]
│   │   │   ├── Limitacion_fisica_YYYY.csv[cite: 1]
│   │   │   ├── Ed_tradicional_YYYY.csv[cite: 1]
│   │   │   ├── Ed_Flexible_YYYY.csv[cite: 1]
│   │   │   ├── Jornadas_nivel_YYYY.csv[cite: 1]
│   │   │   └── Etnia_YYYY.csv[cite: 1]
│   ├── SIMAT/                          # Municipal rates (MEN)[cite: 1]
│   │   ├── Tasa_Desercion_intra_Departamentos.xlsx[cite: 1]
│   │   ├── Tasa_repitencia_intra_Departamentos.xlsx[cite: 1]
│   │   └── DIVIPOLA.csv               # Lookup table: Municipality name → DANE code[cite: 1]
│   ├── IPM/                            # Multidimensional Poverty Index (DANE-ECV / Terridata)[cite: 1]
│   │   └── IPM_Hogares_YYYY.csv[cite: 1]
│   └── Enrichment/                     # Additional territorial features — all available years[cite: 1]
│       ├── Icfes_Resumen.csv           # Ready — site level × year[cite: 1]
│       ├── PDET_municipios.xlsx        # Ready — 170 municipalities with DANE code[cite: 1]
│       ├── ZOMAC_municipios.xlsx       # Ready — 344 municipalities with DANE code[cite: 1]
│       └── Terridata_completo.csv      # Ready — multi-indicator municipal panel (DNP)[cite: 1]
├── Processed/                          # Pipeline outputs (generated programmatically)[cite: 1]
│   ├── panel_maestro.parquet[cite: 1]
│   ├── panel_maestro.csv[cite: 1]
│   └── Diccionario_de_Datos_Panel_Maestro.xlsx[cite: 1]
└── External/
└── DIVIPOLA_referencia.csv[cite: 1]



---

## 4. Summary of Master Panel Feature Domains (70 Variables)

The consolidated dataset (`panel_maestro.parquet`) integrates **70 variables** across **8 thematic domains**:

| Domain # | Domain Name | Count | Aggregation Level | Primary Data Source | Key Features Included |
|---|---|---|---|---|---|
| **1** | **Identification & Geography** | 6 | Site / Municipal / Dept | DANE DIVIPOLA | `SEDE_CODIGO`, `PERIODO_ANIO`, `SAMPLE`, `COD_MPIO_DANE`, `COD_DPTO_DANE`, `REGION_DANE` |
| **2** | **Municipal Rates & Indicators** | 5 | Municipality | Mineducación (SINEB) | `TASA_DESERCION_MPIO`, `TASA_REPITENCIA_MPIO`, `DESERCION_LAG1`, `REPITENCIA_LAG1`, `DESERCION_MA2_LAG` |
| **3** | **Enrollment Dynamics** | 5 | Educational Site | DANE (C-600) | `MATRICULA_TOTAL`, `FLAG_PANDEMIA`, `MATRICULA_DELTA`, `MATRICULA_PCT_CAMBIO`, `FLAG_DECLIVE_MATRICULA` |
| **4** | **Population Characterization** | 15 | Educational Site | DANE C-600 Microdata | Displaced students (`DESPLAZADOS_*`), Disabilities (`LIMITACION_*`), Traditional models (`TRADICIONAL_*`), Flexible models (`FLEXIBLE_*`), Ethnic groups (`ETNIA_*`) |
| **5** | **Proportions & Synthetic Indices** | 7 | Educational Site | Calculated (C-600) | `PROP_DESPLAZADOS`, `PROP_LIMITACION`, `PROP_TRADICIONAL`, `PROP_FLEXIBLE`, `PROP_ETNIA`, `IDX_FEMINIDAD`, `INDICE_VULNERABILIDAD` |
| **6** | **ICFES Saber 11° Performance** | 14 | Educational Site | DataIcfes (Saber 11) | `ICFES_PROM_PUNT_GLOBAL`, Subtest scores (Math, Reading, Sciences, Socials, English), `ICFES_PROM_INSE`, `% Estrato 1-2`, `% Internet`, `% Computer`, `% Unpaid Labor`, `% Campesina` |
| **7** | **Multidimensional Poverty (IPM)** | 16 | Municipality | DANE / DNP Terridata | Deprivation rates in school attendance, school lag, child labor, overcrowding, informal employment, literacy, health, water/sewage, and overall `IPM_IPM` |
| **8** | **Territorial & Conflict Flags** | 2 | Municipality | FINAGRO / ART / MinHacienda | `FLAG_PDET` (170 municipalities), `FLAG_ZOMAC` (344 municipalities) |

---

### Detailed Source Descriptions

#### Source 1 — DANE C-600 Census (Site Level)
* **Description:** DANE's annual enrollment census covering every educational site in Colombia. It serves as the primary predictor source and highest-granularity dataset.
* **Extraction Method:** Downloaded from DANE's microdata catalog (`latin1` encoding).
* **Critical Technical Note:** `SEDE_CODIGO` must be imported as a string and zero-padded to 12 digits using `zfill(12)` to prevent scientific notation truncation.
* **Direct Link:** https://microdatos.dane.gov.co/index.php/catalog/834/get-microdata

#### Source 2 — MEN SINEB System (Municipal Level)
* **Description:** Contains intra-annual dropout and grade repetition rates from the Ministry of National Education (MEN). Filters exclusively for `TERRITORIO = MUNICIPIO` and `SECTOR = Oficial`.
* **Key Columns:** `TASA_DESERCION_MPIO`, `TASA_REPITENCIA_MPIO`, `DESERCION_LAG1`, `REPITENCIA_LAG1`, `DESERCION_MA2_LAG`.
* **Direct Link:** http://bi.mineducacion.gov.co:8380/eportal/web/sineb/22.-tasa-de-desercion-intra-anual

#### Source 3 — ICFES Saber 11° Results (Site Level)
* **Description:** School performance metrics and student socio-economic indicators.
* **Key Features:** Average global score (`ICFES_PROM_PUNT_GLOBAL`), subject scores, average socio-economic index (`ICFES_PROM_INSE`), percent with internet access, percent with computer, percent working unpaid hours, and percent rural/campesina population.
* **Direct Link:** https://bitly.ws/3f3YC

#### Source 4 — DNP Terridata & DANE IPM 2024 (Municipal Level)
* **Description:** 16 indicators measuring specific dimensions of household multidimensional poverty.
* **Key Features:** School non-attendance rate (`IPM_INASISTENCIA_ESCOLAR`), educational lag (`IPM_REZAGO_ESCOLAR`), child labor (`IPM_TRABAJO_INFANTIL`), overcrowding, housing quality, health coverage, and composite `IPM_IPM`.
* **Direct Link:** https://www.datos.gov.co/dataset/Indice-de-Pobreza-Multidimensional-IPM-2024/ntk3-fdqa/about_data

#### Source 5 — Territorial & Conflict Classifications (PDET & ZOMAC)
* **Description:** Special territorial designations indicating conflict impact and priority government focus.
* **Key Features:** `FLAG_PDET` (170 priority municipalities) and `FLAG_ZOMAC` (344 conflict-affected municipalities).
* **Direct Links:**
  - PDET: https://www.finagro.com.co/sites/default/files/documents/2022-02/ANEXO%20MUNICIPIOS%20PDET.xlsx
  - ZOMAC: https://www.finagro.com.co/sites/default/files/documents/2022-02/ANEXO%20MUNICIPIOS%20ZOMAC.xlsx
  - DIVIPOLA: https://www.datos.gov.co/api/views/gdxc-w37w/rows.csv?accessType=DOWNLOAD
"""
