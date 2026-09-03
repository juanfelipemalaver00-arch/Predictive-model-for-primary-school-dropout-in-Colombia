library(data.table)

# 1. Definición de rutas y funciones de normalización
ruta_carpeta <- "C:/Users/DELL/Downloads/Icfes_Raw"
ruta_salida  <- "C:/Users/DELL/OneDrive/Escritorio/UNIVERSIDAD/Maestria Business A/Proyecto Empresarial/Data/Raw/Enrichment/Icfes_Resumen.csv"

normalizar_codigo_12 <- function(x) {
  x <- as.character(x)
  x <- trimws(x)
  x[x %in% c("", "NA", "N/A", "NULL", "NaN")] <- NA_character_
  x <- sub("\\.0+$", "", x)
  x <- gsub("[^0-9]", "", x)
  idx <- !is.na(x) & nchar(x) < 12
  if (any(idx)) x[idx] <- sprintf("%012s", x[idx])
  x[nchar(x) != 12] <- NA_character_
  return(x)
}

# 2. Cargar y consolidar archivos RAW
archivos <- list.files(path = ruta_carpeta, pattern = "\\.(txt|csv)$", full.names = TRUE)

icfes_consolidado <- rbindlist(
  lapply(archivos, function(archivo) {
    message("Cargando: ", basename(archivo))
    df <- fread(
      file = archivo,
      sep = "auto",
      encoding = "UTF-8",
      colClasses = "character",
      fill = TRUE
    )
    # Homogenizar nombres de columnas a minúsculas
    setnames(df, tolower(names(df)))
    df[, archivo_origen := basename(archivo)]
    return(df)
  }),
  use.names = TRUE,
  fill = TRUE
)

gc()

# 3. Normalización de identificadores clave y año
icfes_consolidado[, `:=`(
  cole_cod_dane_sede            = normalizar_codigo_12(cole_cod_dane_sede),
  cole_cod_dane_establecimiento = normalizar_codigo_12(cole_cod_dane_establecimiento),
  anio                          = as.integer(substr(trimws(periodo), 1, 4))
)]

# 4. Transformación de variables continuas y categóricas
cols_num <- c("punt_global", "punt_lectura_critica", "punt_matematicas", 
              "punt_c_naturales", "punt_sociales_ciudadanas", "punt_ingles", 
              "estu_inse_individual")

cols_presentes <- intersect(cols_num, names(icfes_consolidado))
icfes_consolidado[, (cols_presentes) := lapply(.SD, as.numeric), .SDcols = cols_presentes]

# Indicadores socioeconómicos y contextuales (1 / 0 / NA)
icfes_consolidado[, `:=`(
  internet_val = fifelse(fami_tieneinternet == "Si", 1, fifelse(fami_tieneinternet == "No", 0, NA_real_)),
  computador_val = fifelse(fami_tienecomputador == "Si", 1, fifelse(fami_tienecomputador == "No", 0, NA_real_)),
  
  # Estratos bajos (1 y 2)
  estrato_1_2_val = fifelse(fami_estratovivienda %in% c("Estrato 1", "Estrato 2"), 1, 
                            fifelse(!is.na(fami_estratovivienda) & fami_estratovivienda != "", 0, NA_real_)),
  
  # Horas de trabajo no remunerado
  trab_noremu_val = fifelse(!is.na(estu_horastrabnoremu) & !(trimws(estu_horastrabnoremu) %in% c("0", "0 horas", "Ninguna", "")), 1, 0),
  
  # Desplazamiento
  desplaza_val = fifelse((!is.na(estu_desplazacolegio) & !(trimws(estu_desplazacolegio) %in% c("0", "", "No"))) |
                           (!is.na(estu_tiempocasaacole) & !(trimws(estu_tiempocasaacole) %in% c("0", "", "Menos de 15 minutos"))), 1, 0),
  
  # Comunidad campesina
  campesino_val = fifelse(estu_comunidadcampesina == "Si", 1, fifelse(estu_comunidadcampesina == "No", 0, NA_real_))
)]

# 5. Agregación a nivel SEDE - ESTABLECIMIENTO - AÑO
icfes_resumen <- icfes_consolidado[
  !is.na(anio),
  .(
    cant_estudiantes         = .N,
    
    # Rendimiento académico general y por materia
    prom_punt_global         = round(mean(punt_global, na.rm = TRUE), 2),
    prom_punt_lectura        = round(mean(punt_lectura_critica, na.rm = TRUE), 2),
    prom_punt_matematicas    = round(mean(punt_matematicas, na.rm = TRUE), 2),
    prom_punt_ciencias       = round(mean(punt_c_naturales, na.rm = TRUE), 2),
    prom_punt_sociales       = round(mean(punt_sociales_ciudadanas, na.rm = TRUE), 2),
    prom_punt_ingles         = round(mean(punt_ingles, na.rm = TRUE), 2),
    
    # Nivel Socioeconómico e infraestructura
    prom_inse_individual     = round(mean(estu_inse_individual, na.rm = TRUE), 2),
    pct_estrato_1_2          = round(mean(estrato_1_2_val, na.rm = TRUE) * 100, 2),
    pct_fami_tieneinternet   = round(mean(internet_val, na.rm = TRUE) * 100, 2),
    pct_fami_tienecomputador = round(mean(computador_val, na.rm = TRUE) * 100, 2),
    
    # Factores de vulnerabilidad y transporte
    pct_desplazacolegio      = round(mean(desplaza_val, na.rm = TRUE) * 100, 2),
    pct_horastrabnoremu      = round(mean(trab_noremu_val, na.rm = TRUE) * 100, 2),
    pct_comunidadcampesina   = round(mean(campesino_val, na.rm = TRUE) * 100, 2)
  ),
  by = .(
    cole_cod_dane_sede,
    cole_cod_dane_establecimiento, # NECESARIO para el rescate en Python
    cole_nombre_sede,
    cole_nombre_establecimiento,
    cole_depto_ubicacion,
    cole_mcpio_ubicacion,
    cole_cod_mcpio_ubicacion,
    cole_naturaleza,
    cole_area_ubicacion,
    anio
  )
]

# 6. Guardar dataset procesado
dir.create(dirname(ruta_salida), recursive = TRUE, showWarnings = FALSE)
fwrite(icfes_resumen, file = ruta_salida, sep = ",", bom = TRUE)

message("Resumen de ICFES generado con exito. Filas: ", nrow(icfes_resumen))
