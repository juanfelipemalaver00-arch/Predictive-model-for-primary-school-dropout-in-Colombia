#_______________________________________________________________________________
#                        Procesamiento y Analisis exploratorio                                  
#_______________________________________________________________________________
# Juan Malaver
# Este codigo procesa y caracteriza los datos iniciales para dejarlos listos
# para el analisis univariado y check de calidad de datos
#_______________________________________________________________________________

if (!require("pacman")) install.packages("pacman"); library(pacman)
p_load(data.table, dplyr, sf, ggplot2, readxl, viridis, tidyr, stringr, scales,ggrepel)

# Directorio del proyecto ----
if (Sys.info()[["user"]] == "urosario") {
  project_dir <- 'C:/Users/urosario/Dropbox/Research/AfricanParks/'
} else if (Sys.info()[["user"]] == "juanf") {
  project_dir <- 'C:/Users/juanf/OneDrive/Escritorio/UNIVERSIDAD/RA 2024/AfricanParks/'
} else if (Sys.info()[["user"]] == "DELL") {
  setwd('C:/Users/DELL/OneDrive/Escritorio/UNIVERSIDAD/Maestria Business A/Proyecto Empresarial/')
} else if (Sys.info()[["user"]] == "santiago.saavedrap") {
  project_dir <- 'C:/Users/santiago.saavedrap/Dropbox/Research/AfricanParks/'
} else {
  project_dir <- 'C:/Users/Mineria.ra/Dropbox/Research/AfricanParks/'
}

## ============================================================================
## 2. ANÁLISIS EXPLORATORIO Y DE CALIDAD PRELIMINAR (EDA)
## Predicción de riesgo de deserción escolar - Sede educativa
## ============================================================================

# ----------------------------------------------------------------------------
# 1. PREPARACIÓN DEL ENTORNO
# ----------------------------------------------------------------------------
paquetes <- c("tidyverse", "readxl", "e1071", "scales", "patchwork", "janitor", "knitr")
nuevos_paquetes <- paquetes[!(paquetes %in% installed.packages()[, "Package"])]
if (length(nuevos_paquetes)) install.packages(nuevos_paquetes)

library(tidyverse)
library(readxl)
library(e1071)
library(scales)
#library(patchwork)
library(janitor)
library(knitr)

dir.create("Figures", showWarnings = FALSE)
dir.create("Tables",  showWarnings = FALSE)

# Tema visual APA: fuente serif, fondo blanco, líneas sobrias, sin grid mayor
tema_apa <- theme_minimal(base_family = "serif", base_size = 12) +
  theme(
    plot.title    = element_text(face = "bold", size = 13, hjust = 0),
    plot.subtitle = element_text(size = 10, color = "grey30", hjust = 0),
    axis.title    = element_text(size = 11),
    axis.text     = element_text(size = 10, color = "black"),
    panel.grid.minor = element_blank(),
    panel.grid.major = element_line(color = "grey88", linewidth = 0.3),
    legend.position  = "bottom",
    legend.title     = element_text(size = 10),
    plot.caption     = element_text(size = 8, color = "grey40", hjust = 1)
  )
theme_set(tema_apa)

paleta_apa <- c("#2C3E50", "#7F8C8D", "#A93226", "#1F618D", "#717D7E")

guardar_figura <- function(plot, nombre, ancho = 9, alto = 5.5) {
  ggsave(file.path("Figures", paste0(nombre, ".png")), plot = plot,
         width = ancho, height = alto, dpi = 320, bg = "white")
}

# ----------------------------------------------------------------------------
# 2. INGESTIÓN DE DATOS CRUDOS (con manejo de errores por archivo)
# ----------------------------------------------------------------------------
cargar_seguro <- function(ruta, tipo = "csv", ...) {
  tryCatch({
    if (tipo == "csv") {
      df <- read_csv(ruta, locale = locale(encoding = "latin1"), ...)
    } else {
      df <- read_excel(ruta, ...)
    }
    df <- janitor::clean_names(df)
    message(sprintf("OK   | %-60s | %6d filas | %3d columnas", basename(ruta), nrow(df), ncol(df)))
    df
  }, error = function(e) {
    message(sprintf("FAIL | %-60s | %s", basename(ruta), e$message))
    NULL
  })
}

cat("\n>>> INICIANDO CARGA DE BASES DE DATOS...\n")

df_desercion  <- cargar_seguro("Data/Raw/SIMAT/Tasa_Desercion_intra_Departamentos.xlsx", "xlsx", sheet = 1, skip = 5)
df_repitencia <- cargar_seguro("Data/Raw/SIMAT/Tasa_repitencia_intra_Departamentos.xlsx", "xlsx", sheet = 1, skip = 5)
df_ipm        <- cargar_seguro("Data/Raw/IPM/IPM_Hogares_2022.csv")

rutas_c600 <- c(
  desplazados  = "Data/Raw/C-600/2022/Alumnos_Conflicto_A/Alumnos desplazados del conflicto armado, según sexo por nivel educativo y jornada.CSV",
  discapacidad = "Data/Raw/C-600/2022/Alumnos_Discapacidad/Alumnos con discapacidad o algún tipo de condición según sexo por nivel educativo y jornada.CSV",
  tradicional  = "Data/Raw/C-600/2022/Alumnos_Ed_Trad/Alumnos matriculados en educación tradicional y CLEI según rangos de edad por jornada.CSV",
  etnicos      = "Data/Raw/C-600/2022/Alumnos_Etnicos/Alumnos pertenecientes a grupos étnicos según sexo por nivel educativo y jornada.CSV",
  flexibles    = "Data/Raw/C-600/2022/Alumnos_Edu_Flexible/Alumnos matriculados en modelos educativos flexibles según rangos de edad por jornada.CSV",
  jornadas     = "Data/Raw/C-600/2022/Alumnos_Por_Jornadas/Alumnos matriculados por jornadas y nivel educativo (educación tradicional, CLEI y modelos educativos).CSV"
)

# Lista nombrada con las 6 fuentes C-600 (cada elemento puede tener columnas propias)
lista_c600 <- map(rutas_c600, ~ cargar_seguro(.x, "csv", col_types = cols(.default = "c")))

# Lista maestra con las 9 fuentes para los bucles de perfilamiento genérico
fuentes <- c(
  list(simat_desercion  = df_desercion,
       simat_repitencia = df_repitencia,
       ipm_hogares      = df_ipm),
  lista_c600
)
fuentes <- compact(fuentes)  # descarta cualquier fuente que falló en la carga

cat(">>> CARGA FINALIZADA. Fuentes cargadas con éxito:", length(fuentes), "de 9.\n")

# ----------------------------------------------------------------------------
# 3. UTILITARIOS DE DETECCIÓN AUTOMÁTICA DE COLUMNAS
# ----------------------------------------------------------------------------
# Las 6 fuentes C-600 comparten una columna esqueleto (sede, periodo, jornada,
# nivel) pero cada una agrega columnas propias de su categoría poblacional.
# Estas funciones detectan por PATRÓN DE NOMBRE y TIPO, no por nombre fijo.

detectar_columna <- function(df, patrones) {
  nombres <- names(df)
  hit <- nombres[str_detect(nombres, regex(paste(patrones, collapse = "|"), ignore_case = TRUE))]
  if (length(hit) == 0) return(NA_character_)
  hit[1]
}

# Detecta automáticamente todas las columnas numéricas de conteo (cantidad_*)
# presentes en cada fuente C-600, sin asumir que existan en todas
detectar_columnas_conteo <- function(df) {
  nombres <- names(df)
  candidatas <- nombres[str_detect(nombres, regex("cantidad|total|alumno", ignore_case = TRUE))]
  # Validar que sean convertibles a numérico (las C-600 vienen como texto "c")
  candidatas[map_lgl(candidatas, ~ {
    v <- suppressWarnings(as.numeric(df[[.x]]))
    mean(!is.na(v)) > 0.5  # al menos 50% de los valores son numéricos válidos
  })]
}

clasificar_tipo_variable <- function(vector) {
  if (is.numeric(vector)) return("Numérica")
  v_num <- suppressWarnings(as.numeric(as.character(vector)))
  if (mean(!is.na(v_num)) > 0.9 && length(unique(na.omit(v_num))) > 2) return("Numérica (texto)")
  if (length(unique(na.omit(vector))) <= 2) return("Binaria")
  "Categórica"
}

# ----------------------------------------------------------------------------
# 4. PERFILAMIENTO GENERAL: ESTRUCTURA Y VOLUMETRÍA
# ----------------------------------------------------------------------------
tabla_volumetria <- map_dfr(names(fuentes), function(nombre) {
  df <- fuentes[[nombre]]
  tibble(
    Fuente            = nombre,
    Filas             = nrow(df),
    Columnas          = ncol(df),
    Columnas_Conteo   = length(detectar_columnas_conteo(df)),
    Peso_Memoria_MB   = round(as.numeric(object.size(df)) / 1024^2, 2)
  )
})

write_csv(tabla_volumetria, "Tables/Tabla_01_volumetria.csv")
kable(tabla_volumetria, caption = "Tabla 1. Volumetría y estructura general de las fuentes de datos")

# ----------------------------------------------------------------------------
# 5. DIMENSIÓN DE CALIDAD 1 — COMPLETITUD
# ----------------------------------------------------------------------------
calcular_completitud <- function(df, nombre) {
  df %>%
    summarise(across(everything(), ~ sum(is.na(.) | . == "") / n() * 100)) %>%
    pivot_longer(everything(), names_to = "Variable", values_to = "Pct_Faltantes") %>%
    mutate(Fuente = nombre, .before = 1)
}

reporte_completitud <- map2_dfr(fuentes, names(fuentes), calcular_completitud)

# Resumen: completitud promedio por fuente (para el cuerpo del texto/figura)
resumen_completitud <- reporte_completitud %>%
  group_by(Fuente) %>%
  summarise(
    Pct_Faltantes_Promedio = round(mean(Pct_Faltantes), 2),
    N_Variables_Criticas    = sum(Pct_Faltantes > 15),  # umbral de criticidad
    .groups = "drop"
  ) %>%
  arrange(desc(Pct_Faltantes_Promedio))

write_csv(reporte_completitud, "Tables/Tabla_02_completitud_detalle.csv")
write_csv(resumen_completitud, "Tables/Tabla_02b_completitud_resumen.csv")

# Figura 1: completitud por fuente (ordenado, formato APA)
fig_completitud <- resumen_completitud %>%
  mutate(Fuente = fct_reorder(Fuente, Pct_Faltantes_Promedio)) %>%
  ggplot(aes(x = Fuente, y = Pct_Faltantes_Promedio)) +
  geom_col(fill = paleta_apa[1], width = 0.65) +
  geom_text(aes(label = paste0(Pct_Faltantes_Promedio, "%")), hjust = -0.15, size = 3.2, family = "serif") +
  coord_flip() +
  scale_y_continuous(expand = expansion(mult = c(0, 0.15))) +
  labs(title = "Figura 4. Porcentaje promedio de valores faltantes por fuente",
       subtitle = "Calculado como promedio simple del porcentaje de nulos de cada variable dentro de la fuente",
       x = NULL, y = "Porcentaje de valores faltantes (%)",
       caption = "Fuente: elaboración propia a partir de SIMAT-MEN, DANE C-600 y DANE-IPM (2018-2022).")

guardar_figura(fig_completitud, "Figure_04_completitud_por_fuente")

# ----------------------------------------------------------------------------
# 6. DIMENSIÓN DE CALIDAD 2 — CONSISTENCIA (reglas lógicas de negocio)
# ----------------------------------------------------------------------------
# Regla 1: el conteo no puede superar el total de matrícula del segmento
regla_consistencia_simat <- function(df, var_conteo, nombre_indicador) {
  if (!all(c(var_conteo, "total") %in% names(df))) return(NULL)
  df %>%
    filter(!is.na(.data[[var_conteo]]), !is.na(total)) %>%
    summarise(
      Indicador = nombre_indicador,
      N_Evaluado = n(),
      N_Inconsistentes = sum(.data[[var_conteo]] > total),
      Pct_Inconsistentes = round(N_Inconsistentes / N_Evaluado * 100, 3)
    )
}

consistencia_simat <- bind_rows(
  regla_consistencia_simat(df_desercion,  "desertores", "Deserción: DESERTORES > TOTAL"),
  regla_consistencia_simat(df_repitencia, "repitentes", "Repitencia: REPITENTES > TOTAL")
)

# Regla 2 (C-600): la suma hombres + mujeres declarada no debe exceder el total
# de la sede si existe una columna de total explícita; se evalúa solo si aplica
regla_consistencia_c600 <- function(df, nombre_fuente) {
  cols_conteo <- detectar_columnas_conteo(df)
  col_hombre <- detectar_columna(df, c("hombre"))
  col_mujer  <- detectar_columna(df, c("mujer"))
  if (is.na(col_hombre) || is.na(col_mujer)) return(NULL)
  
  h <- suppressWarnings(as.numeric(df[[col_hombre]]))
  m <- suppressWarnings(as.numeric(df[[col_mujer]]))
  tibble(
    Fuente = nombre_fuente,
    Indicador = "Conteos negativos en matrícula por sexo (error de digitación)",
    N_Evaluado = sum(!is.na(h) & !is.na(m)),
    N_Inconsistentes = sum((h < 0 | m < 0), na.rm = TRUE),
    Pct_Inconsistentes = round(sum((h < 0 | m < 0), na.rm = TRUE) / sum(!is.na(h) & !is.na(m)) * 100, 3)
  )
}

consistencia_c600 <- map2_dfr(lista_c600, names(lista_c600), regla_consistencia_c600)

tabla_consistencia <- bind_rows(consistencia_simat, consistencia_c600)
write_csv(tabla_consistencia, "Tables/Tabla_03_consistencia.csv")
kable(tabla_consistencia, caption = "Tabla 3. Resultados de las reglas de consistencia lógica aplicadas")

# ----------------------------------------------------------------------------
# 7. DIMENSIÓN DE CALIDAD 3 — EXACTITUD (validación cruzada contra referente externo)
# ----------------------------------------------------------------------------
# Aproximación de exactitud: comparar el total nacional agregado de matrícula
# implícito en SIMAT (TOTAL) contra el total nacional agregado del C-600 de
# jornadas (fuente más cercana a un censo de matrícula total), para el mismo año.
exactitud_cruce <- tryCatch({
  total_simat_nacional <- df_desercion %>%
    filter(territorio == "NACIONAL", año == 2022) %>%
    summarise(total = sum(total, na.rm = TRUE)) %>% pull(total)
  
  col_total_jornadas <- detectar_columna(lista_c600$jornadas, c("cantidad_total", "total_alumnos", "matricula"))
  if (is.na(col_total_jornadas)) {
    cols_conteo <- detectar_columnas_conteo(lista_c600$jornadas)
    total_c600_nacional <- sum(suppressWarnings(as.numeric(unlist(lista_c600$jornadas[cols_conteo]))), na.rm = TRUE)
  } else {
    total_c600_nacional <- sum(suppressWarnings(as.numeric(lista_c600$jornadas[[col_total_jornadas]])), na.rm = TRUE)
  }
  
  tibble(
    Fuente_A = "SIMAT (TOTAL matrícula nacional 2022)",
    Valor_A  = total_simat_nacional,
    Fuente_B = "C-600 Jornadas (matrícula nacional 2022, suma de columnas de conteo)",
    Valor_B  = total_c600_nacional,
    Diferencia_Absoluta = abs(total_simat_nacional - total_c600_nacional),
    Diferencia_Pct = round(abs(total_simat_nacional - total_c600_nacional) / total_simat_nacional * 100, 2)
  )
}, error = function(e) {
  message("No fue posible calcular el cruce de exactitud: ", e$message)
  NULL
})

if (!is.null(exactitud_cruce)) {
  write_csv(exactitud_cruce, "Tables/Tabla_04_exactitud_cruce.csv")
  kable(exactitud_cruce, caption = "Tabla 4. Validación cruzada de exactitud entre SIMAT y C-600")
}

# ----------------------------------------------------------------------------
# 8. DIMENSIÓN DE CALIDAD 4 Y 5 — DISTRIBUCIÓN, SESGO Y OUTLIERS
# ----------------------------------------------------------------------------
perfilar_numerica <- function(vector, fuente, variable) {
  v <- suppressWarnings(as.numeric(vector))
  v <- v[!is.na(v)]
  if (length(v) < 10) return(NULL)
  
  q1 <- quantile(v, 0.25); q3 <- quantile(v, 0.75); iqr_v <- q3 - q1
  lim_inf <- q1 - 1.5 * iqr_v; lim_sup <- q3 + 1.5 * iqr_v
  n_outliers <- sum(v < lim_inf | v > lim_sup)
  
  tibble(
    Fuente = fuente, Variable = variable,
    N = length(v), Media = round(mean(v), 4), Mediana = round(median(v), 4),
    DE = round(sd(v), 4), Min = round(min(v), 4), Max = round(max(v), 4),
    Skewness = round(skewness(v), 3), Kurtosis = round(kurtosis(v), 3),
    Pct_Outliers_IQR = round(n_outliers / length(v) * 100, 2)
  )
}

# Variables continuas clave de las fuentes principales (SIMAT + IPM)
perfil_numerico <- bind_rows(
  perfilar_numerica(df_desercion$tasa,  "SIMAT Deserción",  "tasa"),
  perfilar_numerica(df_repitencia$tasa, "SIMAT Repitencia", "tasa"),
  perfilar_numerica(df_ipm$ipm,         "DANE IPM Hogares", "ipm"),
  perfilar_numerica(df_ipm$personas,    "DANE IPM Hogares", "personas")
)

# Variables de conteo detectadas automáticamente en cada fuente C-600
perfil_c600 <- map2_dfr(lista_c600, names(lista_c600), function(df, nombre) {
  cols <- detectar_columnas_conteo(df)
  if (length(cols) == 0) return(NULL)
  map_dfr(cols, ~ perfilar_numerica(df[[.x]], nombre, .x))
})

tabla_distribucion <- bind_rows(perfil_numerico, perfil_c600)
write_csv(tabla_distribucion, "Tables/Tabla_05_distribucion_sesgo_outliers.csv")
kable(tabla_distribucion, caption = "Tabla 5. Estadísticos de tendencia central, dispersión, asimetría y outliers")

# Figura 5: distribuciones de las tasas SIMAT (histograma + densidad)
fig_dist_simat <- bind_rows(
  df_desercion  %>% transmute(tasa, Indicador = "Deserción"),
  df_repitencia %>% transmute(tasa, Indicador = "Repitencia")
) %>%
  filter(!is.na(tasa)) %>%
  ggplot(aes(x = tasa, fill = Indicador)) +
  geom_histogram(aes(y = after_stat(density)), bins = 40, alpha = 0.75, position = "identity", color = "white") +
  geom_density(aes(color = Indicador), linewidth = 0.8, fill = NA) +
  scale_fill_manual(values = paleta_apa[1:2]) +
  scale_color_manual(values = paleta_apa[1:2]) +
  facet_wrap(~Indicador, ncol = 2) +
  labs(title = "Figura 5. Distribución empírica de las tasas municipales de deserción y repitencia",
       subtitle = "Histograma con curva de densidad superpuesta, 2018-2022",
       x = "Tasa (proporción)", y = "Densidad",
       caption = "Fuente: elaboración propia a partir de SIMAT-MEN (2018-2022).") +
  guides(fill = "none", color = "none")

guardar_figura(fig_dist_simat, "Figure_05_distribucion_tasas_simat")

# Figura 6: boxplots comparativos para visualizar outliers IQR
fig_outliers <- bind_rows(
  df_desercion  %>% transmute(tasa, Indicador = "Deserción"),
  df_repitencia %>% transmute(tasa, Indicador = "Repitencia")
) %>%
  filter(!is.na(tasa)) %>%
  ggplot(aes(x = Indicador, y = tasa, fill = Indicador)) +
  geom_boxplot(outlier.color = paleta_apa[3], outlier.alpha = 0.4, outlier.size = 0.8, width = 0.5) +
  scale_fill_manual(values = paleta_apa[1:2]) +
  labs(title = "Figura 3. Identificación de valores atípicos mediante rango intercuartílico (IQR)",
       subtitle = "Los puntos en color resaltado representan observaciones fuera de 1.5×IQR",
       x = NULL, y = "Tasa (proporción)",
       caption = "Fuente: elaboración propia a partir de SIMAT-MEN (2018-2022).") +
  guides(fill = "none")

guardar_figura(fig_outliers, "Figure_06_outliers_iqr_tasas", ancho = 7, alto = 5.5)


# Figura 7: distribución del IPM y su relación con la clasificación binaria 'pobre'
fig_ipm <- df_ipm %>%
  ggplot(aes(x = ipm, fill = factor(pobre, labels = c("No pobre", "Pobre multidimensional")))) +
  geom_histogram(bins = 45, alpha = 0.85, color = "white") +
  geom_vline(xintercept = 0.333, linetype = "dashed", color = paleta_apa[3], linewidth = 0.6) +
  scale_fill_manual(values = paleta_apa[1:2], name = "Clasificación") +
  annotate("text", x = 0.333, y = Inf, label = "Umbral 33.3%", vjust = 1.5, hjust = -0.1, family = "serif", size = 3, color = paleta_apa[3]) +
  labs(title = "Figura 7. Distribución del Índice de Pobreza Multidimensional por hogar",
       subtitle = "Línea punteada: umbral oficial de clasificación de pobreza multidimensional (DANE, 2022)",
       x = "IPM (proporción de privaciones ponderadas)", y = "Número de hogares",
       caption = "Fuente: elaboración propia a partir de DANE - Encuesta Nacional de Calidad de Vida (2022).")

guardar_figura(fig_ipm, "Figure_07_distribucion_ipm")

# ----------------------------------------------------------------------------
# 9. MATRIZ INTEGRAL DE AUDITORÍA DE CALIDAD (5 DIMENSIONES)
# ----------------------------------------------------------------------------
# Cada fila resume las 5 dimensiones para una variable clave, con un
# diagnóstico de riesgo y una recomendación de mitigación accionable.
construir_fila_auditoria <- function(vector, fuente, variable, tipo_dato,
                                     regla_consistencia_pct = NA,
                                     nota_exactitud = NA) {
  v_chr <- as.character(vector)
  faltantes_pct <- round(sum(is.na(v_chr) | v_chr == "") / length(v_chr) * 100, 2)
  
  es_numerica <- tipo_dato %in% c("Numérica", "Numérica (texto)")
  sesgo_val <- NA; outliers_pct <- NA
  if (es_numerica) {
    v_num <- suppressWarnings(as.numeric(vector))
    v_num <- v_num[!is.na(v_num)]
    if (length(v_num) > 10) {
      sesgo_val <- round(skewness(v_num), 2)
      q1 <- quantile(v_num, .25); q3 <- quantile(v_num, .75); iqr_v <- q3 - q1
      outliers_pct <- round(sum(v_num < q1 - 1.5*iqr_v | v_num > q3 + 1.5*iqr_v) / length(v_num) * 100, 2)
    }
  }
  
  riesgo <- "Bajo"
  recomendacion <- "Variable apta para uso directo en el modelamiento."
  if (faltantes_pct > 15) {
    riesgo <- "Alto"
    recomendacion <- "Evaluar imputación o exclusión de registros sin matrícula activa antes del modelamiento."
  } else if (!is.na(regla_consistencia_pct) && regla_consistencia_pct > 1) {
    riesgo <- "Alto"
    recomendacion <- "Depurar registros que violan la regla de consistencia lógica antes de su uso."
  } else if (es_numerica && !is.na(sesgo_val) && abs(sesgo_val) > 2) {
    riesgo <- "Medio"
    recomendacion <- "Sesgo alto: preferir algoritmos de ensamble robustos a asimetría (LightGBM/XGBoost) o aplicar transformación."
  } else if (es_numerica && !is.na(outliers_pct) && outliers_pct > 5) {
    riesgo <- "Medio"
    recomendacion <- "Revisar atípicos estructurales; documentar si corresponden a casos legítimos (sedes pequeñas) antes de truncar."
  }
  
  tibble(
    Fuente = fuente, Variable = variable, Tipo_Dato = tipo_dato,
    Completitud_Faltantes_Pct = faltantes_pct,
    Consistencia_Pct_Inconsistente = regla_consistencia_pct,
    Exactitud_Nota = nota_exactitud,
    Sesgo_Skewness = sesgo_val,
    Outliers_IQR_Pct = outliers_pct,
    Riesgo_Calidad = riesgo,
    Recomendacion = recomendacion
  )
}

matriz_auditoria <- bind_rows(
  construir_fila_auditoria(df_desercion$tasa, "SIMAT (Deserción)", "tasa", "Numérica",
                           regla_consistencia_pct = consistencia_simat$Pct_Inconsistentes[1],
                           nota_exactitud = if (!is.null(exactitud_cruce)) paste0(exactitud_cruce$Diferencia_Pct, "% vs. C-600") else NA),
  construir_fila_auditoria(df_repitencia$tasa, "SIMAT (Repitencia)", "tasa", "Numérica",
                           regla_consistencia_pct = consistencia_simat$Pct_Inconsistentes[2]),
  construir_fila_auditoria(df_ipm$ipm, "DANE (IPM Hogares)", "ipm", "Numérica"),
  construir_fila_auditoria(df_ipm$inasistencia_escolar, "DANE (IPM Privaciones)", "inasistencia_escolar", "Binaria"),
  construir_fila_auditoria(df_ipm$rezago_escolar, "DANE (IPM Privaciones)", "rezago_escolar", "Binaria"),
  construir_fila_auditoria(df_ipm$trabajo_infantil, "DANE (IPM Privaciones)", "trabajo_infantil", "Binaria")
)

# Se agregan automáticamente las variables de conteo de las 6 fuentes C-600
matriz_auditoria_c600 <- map2_dfr(lista_c600, names(lista_c600), function(df, nombre) {
  cols <- detectar_columnas_conteo(df)
  if (length(cols) == 0) return(NULL)
  map_dfr(cols, function(col) {
    construir_fila_auditoria(df[[col]], paste0("C-600 (", nombre, ")"), col,
                             clasificar_tipo_variable(suppressWarnings(as.numeric(df[[col]]))))
  })
})

matriz_auditoria_final <- bind_rows(matriz_auditoria, matriz_auditoria_c600)
write_csv(matriz_auditoria_final, "Tables/Tabla_06_matriz_auditoria_calidad.csv")
kable(matriz_auditoria_final, caption = "Tabla 6. Matriz consolidada de auditoría de calidad de datos (5 dimensiones)")

# ----------------------------------------------------------------------------
# 10. RESUMEN EJECUTIVO EN CONSOLA
# ----------------------------------------------------------------------------
cat("\n========================================================================\n")
cat(" RESUMEN EJECUTIVO DEL DIAGNÓSTICO DE CALIDAD\n")
cat("========================================================================\n")
cat("Fuentes cargadas exitosamente :", length(fuentes), "de 9\n")
cat("Variables con riesgo ALTO     :", sum(matriz_auditoria_final$Riesgo_Calidad == "Alto", na.rm = TRUE), "\n")
cat("Variables con riesgo MEDIO    :", sum(matriz_auditoria_final$Riesgo_Calidad == "Medio", na.rm = TRUE), "\n")
cat("Variables con riesgo BAJO     :", sum(matriz_auditoria_final$Riesgo_Calidad == "Bajo", na.rm = TRUE), "\n")
cat("\nTablas exportadas en /Tables  | Figuras exportadas en /Figures (PNG, 320 dpi)\n")
cat(">>> PROCESO EJECUTADO CORRECTAMENTE.\n")
