#_______________________________________________________________________________
#                        Graficas Exploratorias                                 
#_______________________________________________________________________________
# Juan Malaver
# Graficas iniciales para la introduccion de la tesis
# Maestria en Business Analytics - Proyecto Empresarial
#_______________________________________________________________________________

if (!require("pacman")) install.packages("pacman"); library(pacman)
p_load(data.table, dplyr, sf, ggplot2, readxl, viridis, tidyr, stringr, scales,ggrepel)

# Directorio del proyecto ----
if (Sys.info()[["user"]] == "urosario") {
  project_dir <- 'C:/Users/DELL/OneDrive/Escritorio/UNIVERSIDAD/Maestria Business A/Proyecto Empresarial/'
} else if (Sys.info()[["user"]] == "juanf") {
  project_dir <- 'C:/Users/DELL/OneDrive/Escritorio/UNIVERSIDAD/Maestria Business A/Proyecto Empresarial/'
} else if (Sys.info()[["user"]] == "DELL") {
  setwd('C:/Users/DELL/OneDrive/Escritorio/UNIVERSIDAD/Maestria Business A/Proyecto Empresarial/')
} else if (Sys.info()[["user"]] == "santiago.saavedrap") {
  project_dir <- 'C:/Users/DELL/OneDrive/Escritorio/UNIVERSIDAD/Maestria Business A/Proyecto Empresarial/'
} else {
  project_dir <- 'C:/Users/DELL/OneDrive/Escritorio/UNIVERSIDAD/Maestria Business A/Proyecto Empresarial/'
}

# Carga de datos ----
deptos <- st_read("Figures/F99_SHP_departamento/MGN_ADM_DPTO_POLITICO.shp")

T_Desercion  <- read_excel("Data/Raw/SIMAT/Tasa_Desercion_intra_Departamentos.xlsx",  skip = 5)
T_Repitencia <- read_excel("Data/Raw/SIMAT/Tasa_repitencia_intra_Departamentos.xlsx", skip = 5)


#_______________________________________________________________________________
# GRAFICA 1: Evolución Tasa de Deserción (Delta a 2024)
#_______________________________________________________________________________

# 1. Calcular serie nacional de deserción 
desercion_g1 <- T_Desercion %>%
  filter(SECTOR == "Total", `NIVEL EDUCATIVO` == "Total") %>% 
  group_by(AÑO) %>%
  summarise(
    desertores = sum(DESERTORES, na.rm = TRUE),
    total      = sum(TOTAL,      na.rm = TRUE)
  ) %>%
  mutate(tasa = (desertores / total) * 100) %>%
  filter(AÑO >= 2018, AÑO <= 2024) %>%
  dplyr::select(AÑO, tasa)

# 2. Extraer valores para calcular el Delta (2018 vs 2024)
val_2018 <- desercion_g1$tasa[desercion_g1$AÑO == 2018]
val_2024 <- desercion_g1$tasa[desercion_g1$AÑO == 2024]
delta_val <- val_2024 - val_2018
delta_txt <- paste0(ifelse(delta_val > 0, "+", ""), round(delta_val, 2), " p.p.")

# Definir la altura de la línea punteada superior del delta
y_max_line <- max(desercion_g1$tasa) + 0.4

# 3. Generar la Gráfica
F1 <- ggplot(desercion_g1, aes(x = AÑO, y = tasa)) +
  
  # Línea principal y puntos (Estilo azul corporativo)
  geom_line(color = "#327bb2", linewidth = 1.2) +
  geom_point(color = "#327bb2", size = 3.5) +
  
  # Etiquetas de valores sobre los puntos
  geom_text(aes(label = paste0(round(tasa, 2), "%")), 
            vjust = -1.5, size = 3.5, color = "black") +
  
  # --- CONSTRUCCIÓN DEL MARCADOR DELTA (Líneas punteadas) ---
  # Vertical desde 2018 hacia arriba
  annotate("segment", x = 2018, xend = 2018, y = val_2018 + 0.15, yend = y_max_line, 
           linetype = "dashed", color = "black") +
  # Horizontal desde 2018 hasta 2024
  annotate("segment", x = 2018, xend = 2024, y = y_max_line, yend = y_max_line, 
           linetype = "dashed", color = "black") +
  # Vertical desde la línea superior hasta el punto de 2024
  annotate("segment", x = 2024, xend = 2024, y = y_max_line, yend = val_2024 + 0.15, 
           linetype = "dashed", color = "black") +
  
  # Etiqueta del delta (Estilo Óvalo gris) en la esquina superior derecha
  annotate("label", x = 2024, y = y_max_line, label = delta_txt, 
           fill = "#8e9ba4", color = "white", fontface = "bold", 
           label.r = unit(0.5, "lines"), label.padding = unit(0.4, "lines"), size = 3.5) +
  
  # Escalas y tema (Cuadrícula limpia como en tu imagen)
  scale_x_continuous(breaks = 2018:2024) +
  scale_y_continuous(labels = label_number(suffix = "%"), 
                     expand = expansion(mult = c(0.1, 0.2))) +
  labs(x = "Año", y = "Tasa de Deserción (%)") +
  
  theme_bw(base_size = 12) + # theme_bw da el recuadro cerrado (box)
  theme(
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_line(linetype = "dashed", color = "grey85"),
    panel.grid.major.y = element_line(linetype = "dashed", color = "grey85"),
    axis.text = element_text(size = 11, color = "black"),
    axis.title = element_text(size = 12, color = "black")
  )

ggsave("Figures/F1_evolucion_desercion.png", plot = F1, width = 9, height = 5, dpi = 300, bg = "white")
plot(F1)
cat("✓ Gráfica 1 guardada en Figures/F1_evolucion_desercion.png/n")


#_______________________________________________________________________________
# GRAFICA 2: Mapa de tasa de deserción por departamento (último año disponible)
#_______________________________________________________________________________

# Limpia nombres de columnas para evitar errores por espacios
names(T_Desercion)  <- str_trim(names(T_Desercion))
names(T_Repitencia) <- str_trim(names(T_Repitencia))

# Filtra el año más reciente disponible en los datos
anio_mapa <- max(T_Desercion$AÑO, na.rm = TRUE)

# Extrae el dato consolidado por departamento (filtrando por los totales)
desercion_mapa <- T_Desercion %>%
  filter(
    AÑO == anio_mapa, 
    SECTOR == "Total", 
    `NIVEL EDUCATIVO` == "Total"
  ) %>%
  group_by(DEPARTAMENTO) %>%
  summarise(tasa_deser = 100*mean(TASA, na.rm = TRUE)) %>% 
  ungroup() %>%
  mutate(DEPARTAMENTO = str_to_upper(str_trim(DEPARTAMENTO)))

# Normaliza nombres en el shapefile para el cruce de datos
deptos <- deptos %>%
  mutate(nombre_join = str_to_upper(str_trim(dpto_cnmbr)))

# Une el shapefile espacial con los datos de deserción
mapa_data <- deptos %>%
  left_join(desercion_mapa, by = c("nombre_join" = "DEPARTAMENTO"))

# Genera el mapa
F2 <- ggplot(mapa_data) +
  geom_sf(aes(fill = tasa_deser), color = "white", linewidth = 0.25) +
  scale_fill_viridis(
    option    = "magma",
    direction = -1,
    name      = "Tasa (%)",
    na.value  = "grey85",
    labels    = label_number(suffix = "%", accuracy = 0.01) # Muestra 4 decimales
  ) +
  labs(
    title    = "Tasa de deserción escolar intraanual por departamento",
    subtitle = paste0("Colombia, ", anio_mapa, " — Instituciones oficiales y no oficiales"),
    caption  = paste0(
      "Nota. Elaboración propia con base en datos del MEN citados en/n",
      "Procuraduría General de la Nación (2024, Tabla 2, p. 11)./n",
      "Territorios sin información disponible se muestran en gris."
    )
  ) +
  theme_void(base_size = 11) +
  theme(
    plot.title       = element_text(face = "bold", size = 13, hjust = 0.5, margin = margin(b = 4)),
    plot.subtitle    = element_text(size = 10, hjust = 0.5, color = "grey40", margin = margin(b = 8)),
    plot.caption     = element_text(size = 7.5, color = "grey50", hjust = 0, margin = margin(t = 10)),
    legend.position  = "right",
    legend.title     = element_text(size = 9, face = "bold"),
    legend.key.height= unit(1.2, "cm"),
    plot.margin      = margin(10, 10, 10, 10)
  )

# Guarda el gráfico en la carpeta designada
ggsave("Figures/F2_tasa_desercion_dept.png", plot = F2,
       width = 8, height = 9, dpi = 300, bg = "white")
plot(F2)
cat("✓ Gráfica 2 guardada en Figures/F2_tasa_desercion_dept.png/n")

#_______________________________________________________________________________
# GRAFICA 3: Deserción vs Repitencia — serie histórica nacional (2018–2024)
#_______________________________________________________________________________

# Aplicar filtro de "Total" en Sector y Nivel Educativo antes de agrupar
desercion_nac <- T_Desercion %>%
  filter(SECTOR == "Total", `NIVEL EDUCATIVO` == "Total") %>% 
  group_by(AÑO) %>%
  summarise(
    desertores = sum(DESERTORES, na.rm = TRUE),
    total      = sum(TOTAL,      na.rm = TRUE)
  ) %>%
  mutate(tasa_deser = (desertores / total) * 100) %>%
  filter(AÑO >= 2018, AÑO <= 2024) %>% # <- Actualizado hasta 2024
  dplyr::select(AÑO, tasa_deser)

repitencia_nac <- T_Repitencia %>%
  filter(SECTOR == "Total", `NIVEL EDUCATIVO` == "Total") %>%
  group_by(AÑO) %>%
  summarise(
    repitentes = sum(REPITENTES, na.rm = TRUE),
    total      = sum(TOTAL,      na.rm = TRUE)
  ) %>%
  mutate(tasa_repit = (repitentes / total) * 100) %>%
  filter(AÑO >= 2018, AÑO <= 2024) %>% # <- Actualizado hasta 2024
  dplyr::select(AÑO, tasa_repit)

# Une las dos series
serie <- desercion_nac %>%
  left_join(repitencia_nac, by = "AÑO")

escala <- max(serie$tasa_repit, na.rm = TRUE) / max(serie$tasa_deser, na.rm = TRUE)

F3 <- ggplot(serie, aes(x = AÑO)) +
  
  # Línea y puntos deserción
  geom_line(aes(y = tasa_deser, color = "Deserción"), linewidth = 1.3) +
  geom_point(aes(y = tasa_deser, color = "Deserción"), size = 3.5, shape = 16) +
  
  # Línea y puntos repitencia
  geom_line(aes(y = tasa_repit / escala, color = "Repitencia"), linewidth = 1.3, linetype = "dashed") +
  geom_point(aes(y = tasa_repit / escala, color = "Repitencia"), size = 3.5, shape = 17) +
  
  # Etiquetas Inteligentes con ggrepel (¡Adiós superposición!)
  ggrepel::geom_label_repel(
    aes(y = tasa_deser, label = paste0(round(tasa_deser, 1), "%")),
    color = "#C0392B", fontface = "bold", fill = "white", label.size = NA,
    box.padding = 0.5, point.padding = 0.3, show.legend = FALSE, direction = "y"
  ) +
  ggrepel::geom_label_repel(
    aes(y = tasa_repit / escala, label = paste0(round(tasa_repit, 1), "%")),
    color = "#2980B9", fontface = "bold", fill = "white", label.size = NA,
    box.padding = 0.5, point.padding = 0.3, show.legend = FALSE, direction = "y"
  ) +
  
  scale_y_continuous(
    name   = "Tasa de deserción (%)",
    labels = label_number(suffix = "%", accuracy = 0.1),
    expand = expansion(mult = c(0.15, 0.15)),
    sec.axis = sec_axis(
      ~ . * escala,
      name   = "Tasa de repitencia (%)",
      labels = label_number(suffix = "%", accuracy = 0.1)
    )
  ) +
  scale_x_continuous(breaks = 2018:2024) +
  scale_color_manual(
    values = c("Deserción" = "#C0392B", "Repitencia" = "#2980B9"),
    name   = ""
  ) +
  labs(x = "") + 
  theme_minimal(base_size = 12) +
  theme(
    legend.position    = "bottom",
    legend.text        = element_text(size = 11),
    panel.grid.minor   = element_blank(),
    axis.title.y.left  = element_text(color = "#C0392B", face = "bold", margin = margin(r = 10)),
    axis.title.y.right = element_text(color = "#2980B9", face = "bold", margin = margin(l = 10)),
    plot.margin        = margin(15, 15, 15, 15) 
  )

ggsave("Figures/F3_desercion_vs_repitencia.png", plot = F3, width = 9, height = 5, dpi = 300, bg = "white")
plot(F3)

cat("✓ Gráfica 3 guardada en Figures/F3_desercion_vs_repitencia.png/n")



#ANÁLISIS EXPLORATORIO Y DE CALIDAD PRELIMINAR (EDA) ----

# 1. PREPARACIÓN DEL ENTORNO Y CONFIGURACIÓN
# Se listan e instalan los paquetes necesarios para el procesamiento analítico
paquetes <- c("tidyverse", "readxl", "e1071", "gridExtra")
nuevos_paquetes <- paquetes[!(paquetes %in% installed.packages()[,"Package"])]
if(length(nuevos_paquetes)) install.packages(nuevos_paquetes)

library(tidyverse)
library(readxl)
library(e1071)
library(gridExtra)

# Creación automática de la carpeta de salida para las ilustraciones de la tesis
dir.create("Figures", showWarnings = FALSE)

# 2. INGESTIÓN DE DATOS CRUDOS
cat("\n>>> INICIANDO CARGA DE BASES DE DATOS...\n")

# A. Fuentes del Ministerio de Educación Nacional (MEN)
df_desercion <- read_excel("Data/Raw/SIMAT/Tasa_Desercion_intra_Departamentos.xlsx", sheet = 1, skip = 5)
df_repitencia <- read_excel("Data/Raw/SIMAT/Tasa_repitencia_intra_Departamentos.xlsx", sheet = 1, skip = 5)

# B. Fuentes del DANE - Contexto Socioeconómico (IPM)
df_ipm <- read_csv("Data/Raw/IPM/IPM_Hogares_2022.csv")

# C. Fuentes del DANE - Censo de Educación Formal C-600
df_desplazados  <- read_csv("Data/Raw/C-600/2022/Alumnos_Conflicto_A/Alumnos desplazados del conflicto armado, según sexo por nivel educativo y jornada.CSV", locale = locale(encoding = "latin1"))
df_discapacidad <- read_csv("Data/Raw/C-600/2022/Alumnos_Discapacidad/Alumnos con discapacidad o algún tipo de condición según sexo por nivel educativo y jornada.CSV", locale = locale(encoding = "latin1"))
df_tradicional  <- read_csv("Data/Raw/C-600/2022/Alumnos_Ed_Trad/Alumnos matriculados en educación tradicional y CLEI según rangos de edad por jornada.CSV", locale = locale(encoding = "latin1"))
df_etnicos      <- read_csv("Data/Raw/C-600/2022/Alumnos_Etnicos/Alumnos pertenecientes a grupos étnicos según sexo por nivel educativo y jornada.CSV", locale = locale(encoding = "latin1"))

# Archivos con líneas complejas leídos con tipado flexible para evitar truncamiento
df_flexibles    <- read_csv("Data/Raw/C-600/2022/Alumnos_Edu_Flexible/Alumnos matriculados en modelos educativos flexibles según rangos de edad por jornada.CSV", locale = locale(encoding = "latin1"), col_types = cols(.default = "c"))
df_jornadas     <- read_csv("Data/Raw/C-600/2022/Alumnos_Por_Jornadas/Alumnos matriculados por jornadas y nivel educativo (educación tradicional, CLEI y modelos educativos).CSV", locale = locale(encoding = "latin1"), col_types = cols(.default = "c"))

cat(">>> CARGA FINALIZADA CON ÉXITO.\n")

# 3. ESTRUCTURA Y VOLUMETRÍA DE LOS CONJUNTOS DE DATOS
cat("\n=============================================\n")
cat(" OUTPUT 1: DIMENSIONES ENCONTRADAS (FILAS Y COLUMNAS)\n")
cat("=============================================\n")
dimensiones <- list(
  `SIMAT Deserción` = dim(df_desercion), 
  `SIMAT Repitencia` = dim(df_repitencia), 
  `DANE IPM Hogares` = dim(df_ipm),
  `C600 Desplazados` = dim(df_desplazados), 
  `C600 Discapacidad` = dim(df_discapacidad),
  `C600 Tradicional` = dim(df_tradicional), 
  `C600 Étnicos` = dim(df_etnicos),
  `C600 Flexibles` = dim(df_flexibles), 
  `C600 Jornadas` = dim(df_jornadas)
)
print(dimensiones)

# 4. DIAGNÓSTICO PROFUNDO DE COMPLETITUD (TABLA DE VALORES NULOS)
cat("\n=============================================\n")
cat(" OUTPUT 2: REPORTE COMPLETO DE VALORES NULOS (COMPLETITUD)\n")
cat("=============================================\n")

calcular_completitud <- function(df, nombre) {
  df %>%
    summarise(across(everything(), ~ sum(is.na(.)) / n() * 100)) %>%
    pivot_longer(cols = everything(), names_to = "Variable", values_to = "Porcentaje_Faltantes") %>%
    mutate(Dataset = nombre) %>%
    select(Dataset, Variable, Porcentaje_Faltantes)
}

reporte_faltantes <- bind_rows(
  calcular_completitud(df_desercion, "SIMAT Deserción"),
  calcular_completitud(df_repitencia, "SIMAT Repitencia"),
  calcular_completitud(df_ipm, "DANE IPM Hogares"),
  calcular_completitud(df_desplazados, "C600 Desplazados")
)

# Se fuerza la impresión de todo el dataframe en la consola para tu revisión
print.data.frame(reporte_faltantes, row.names = FALSE)

# 5. ANÁLISIS DE SESGO Y CURTOSIS EN INDICADORES CONTINUOS
cat("\n=============================================\n")
cat(" OUTPUT 3: INDICADORES DE DISTRIBUCIÓN Y ASIMETRÍA\n")
cat("=============================================\n")
indicadores_sesgo <- tibble(
  Variable = c("Tasa_Desercion", "Tasa_Repitencia", "IPM_Hogar"),
  Skewness = c(
    skewness(df_desercion$TASA, na.rm = TRUE),
    skewness(df_repitencia$TASA, na.rm = TRUE),
    skewness(df_ipm$ipm, na.rm = TRUE)
  ),
  Kurtosis = c(
    kurtosis(df_desercion$TASA, na.rm = TRUE),
    kurtosis(df_repitencia$TASA, na.rm = TRUE),
    kurtosis(df_ipm$ipm, na.rm = TRUE)
  )
)
print.data.frame(indicadores_sesgo, row.names = FALSE)

# Control de Consistencia Operacional (Validación lógica institucional)
cat("\n=============================================\n")
cat(" OUTPUT 4: VALIDACIÓN DE REGLAS DE CONSISTENCIA LOGICA\n")
cat("=============================================\n")
consistencia_desercion <- df_desercion %>%
  filter(!is.na(DESERTORES) & !is.na(TOTAL)) %>%
  summarise(Inconsistencias = sum(DESERTORES > TOTAL))
cat("Cantidad de registros anomalos donde Desertores supera la Matrícula Total:", consistencia_desercion$Inconsistencias, "\n")

# 6. EVALUACIÓN DE OUTLIERS ALGORÍTMICOS (MÉTODO IQR)
cat("\n=============================================\n")
cat(" OUTPUT 5: DIAGNÓSTICO DE VALORES ATÍPICOS EXTREMOS (IQR)\n")
cat("=============================================\n")

detectar_outliers_iqr <- function(vector, variable_nombre) {
  q1 <- quantile(vector, 0.25, na.rm = TRUE)
  q3 <- quantile(vector, 0.75, na.rm = TRUE)
  iqr_val <- q3 - q1
  limite_inferior <- q1 - 1.5 * iqr_val
  limite_superior <- q3 + 1.5 * iqr_val
  
  outliers <- sum(vector < limite_inferior | vector > limite_superior, na.rm = TRUE)
  porcentaje_outliers <- (outliers / length(vector)) * 100
  
  cat(paste0("[", variable_nombre, "] Rango Permitido: ", round(limite_inferior, 4), 
             " a ", round(limite_superior, 4), 
             " | Casos detectados: ", outliers, 
             " (", round(porcentaje_outliers, 2), "%)\n"))
}

detectar_outliers_iqr(df_desercion$TASA, "Tasa Deserción SIMAT")
detectar_outliers_iqr(df_repitencia$TASA, "Tasa Repitencia SIMAT")
detectar_outliers_iqr(df_ipm$ipm, "Índice IPM DANE")

# 7. GENERACIÓN Y SALVAGUARDA DE COMPONENTES GRÁFICOS (SECUENCIA DESDE 04)
cat("\n>>> PROCESANDO Y EXPORTANDO COMPONENTES GRÁFICOS EN DIRECTORIO /Figures...\n")

# Figura 04: Perfilamiento de distribuciones base (Histogramas)
p1 <- ggplot(df_desercion, aes(x = TASA)) +
  geom_histogram(fill = "#1f77b4", color = "white", bins = 40, alpha = 0.8) +
  labs(title = "Distribución Empírica de la Tasa de Deserción", x = "Tasa", y = "Frecuencia") +
  theme_minimal()

p2 <- ggplot(df_repitencia, aes(x = TASA)) +
  geom_histogram(fill = "#ff7f0e", color = "white", bins = 40, alpha = 0.8) +
  labs(title = "Distribución Empírica de la Tasa de Repitencia", x = "Tasa", y = "Frecuencia") +
  theme_minimal()

grid_distribucion <- grid.arrange(p1, p2, ncol = 2)
ggsave("Figures/Figure_04_distribuciones_tasas.png", plot = grid_distribucion, width = 12, height = 5)

# Figura 05: Análisis de Series de Tiempo (Evolución histórica agregada de indicadores)
df_linea_desercion <- df_desercion %>% 
  group_by(AÑO) %>% 
  summarise(Media = mean(TASA, na.rm = TRUE), Indicador = "Deserción")

df_linea_repitencia <- df_repitencia %>% 
  group_by(AÑO) %>% 
  summarise(Media = mean(TASA, na.rm = TRUE), Indicador = "Repitencia")

df_historico_consolidado <- bind_rows(df_linea_desercion, df_linea_repitencia)

p3 <- ggplot(df_historico_consolidado, aes(x = AÑO, y = Media, color = Indicador, group = Indicador)) +
  geom_line(size = 1.2) +
  geom_point(size = 3) +
  scale_color_manual(values = c("#1f77b4", "#ff7f0e")) +
  scale_x_continuous(breaks = seq(2015, 2024, 1)) +
  labs(title = "Trayectoria Temporal y Evolución de Deserción vs Repitencia (2015-2024)",
       x = "Ciclo Lectivo (Año)", y = "Tasa Promedio") +
  theme_minimal() +
  theme(legend.position = "bottom")

ggsave("Figures/Figure_05_evolucion_temporal.png", plot = p3, width = 9, height = 5)

# Figura 06: Comportamiento demográfico de poblaciones vulnerables
p4 <- df_desplazados %>%
  filter(PERIODO_ANIO == 2022) %>%
  group_by(NIVELENSE_NOMBRE) %>%
  summarise(Total_Hombres = sum(JORNDES_CANTIDAD_HOMBRE, na.rm = TRUE),
            Total_Mujeres = sum(JORNDES_CANTIDAD_MUJER, na.rm = TRUE)) %>%
  pivot_longer(cols = starts_with("Total"), names_to = "Sexo", values_to = "Cantidad") %>%
  ggplot(aes(x = reorder(NIVELENSE_NOMBRE, -Cantidad), y = Cantidad, fill = Sexo)) +
  geom_col(position = "dodge") +
  scale_fill_manual(values = c("#2ca02c", "#d62728"), labels = c("Hombres", "Mujeres")) +
  labs(title = "Víctimas del Conflicto Armado según Nivel de Enseñanza (2022)", x = "Nivel Educativo", y = "Matrícula Registrada") +
  theme_minimal() + 
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

ggsave("Figures/Figure_06_demografia_desplazados.png", plot = p4, width = 10, height = 6)

# 8. MATRIZ INTEGRAL DE AUDITORÍA DE DATOS PARA REPORTE FORMAL
cat("\n========================================================================\n")
cat(" OUTPUT FINAL: MATRIZ CONSOLIDADA DE CONTROL Y AUDITORÍA DE CALIDAD\n")
cat("========================================================================\n")

generar_fila_auditoria <- function(vector, fuente, variable, tipo_dato) {
  faltantes_pct <- sum(is.na(vector)) / length(vector) * 100
  
  if (is.numeric(vector)) {
    sesgo_val <- round(skewness(vector, na.rm = TRUE), 2)
    q1 <- quantile(vector, 0.25, na.rm = TRUE)
    q3 <- quantile(vector, 0.75, na.rm = TRUE)
    iqr_val <- q3 - q1
    outliers_cnt <- sum(vector < (q1 - 1.5 * iqr_val) | vector > (q3 + 1.5 * iqr_val), na.rm = TRUE)
    outliers_pct <- round((outliers_cnt / length(vector)) * 100, 2)
  } else {
    sesgo_val <- "N/A (Cat.)"
    outliers_pct <- 0.00
  }
  
  diagnostico <- "Óptimo para modelado"
  if (faltantes_pct > 15) {
    diagnostico <- "Crítico: Requiere filtrar registros sin matrícula activa"
  } else if (is.numeric(vector) && abs(as.numeric(sesgo_val)) > 2) {
    diagnostico <- "Sesgo Alto: Recomendable usar algoritmos de ensamble (LightGBM/XGBoost)"
  } else if (outliers_pct > 5) {
    diagnostico <- "Alerta: Presencia de atípicos estructurales por asimetría"
  }
  
  tibble(
    Fuente = fuente,
    Variable = variable,
    `Tipo Dato` = tipo_dato,
    `Faltantes (%)` = round(faltantes_pct, 2),
    `Sesgo (Skewness)` = as.character(sesgo_val),
    `Outliers IQR (%)` = outliers_pct,
    `Diagnóstico Estratégico` = diagnostico
  )
}

matriz_auditoria_datos <- bind_rows(
  generar_fila_auditoria(df_desercion$TASA, "SIMAT (Deserción)", "TASA", "Numérico (Continua)"),
  generar_fila_auditoria(df_repitencia$TASA, "SIMAT (Repitencia)", "TASA", "Numérico (Continua)"),
  generar_fila_auditoria(df_ipm$ipm, "DANE (IPM Hogares)", "ipm", "Numérico (Continua)"),
  generar_fila_auditoria(df_desplazados$JORNDES_CANTIDAD_HOMBRE, "DANE (C600 Conflicto)", "CANTIDAD_HOMBRE", "Numérico (Discreta)"),
  generar_fila_auditoria(df_tradicional$GRADO_NOMBRE, "DANE (C600 Tradicional)", "GRADO_NOMBRE", "Categórico (Nominal)"),
  generar_fila_auditoria(df_ipm$inasistencia_escolar, "DANE (IPM Privaciones)", "inasistencia_escolar", "Numérico (Binaria)")
)

print.data.frame(matriz_auditoria_datos, row.names = FALSE)
cat("\n>>> PROCESO EJECUTADO CORRECTAMENTE. VERIFICA LA CONSOLA Y LA CARPETA /Figures.\n")