  # 1. Cargar la librería (si no la tienes, instala con: install.packages("data.table"))
  library(data.table)
  
  # 2. Definir la ruta de la carpeta (usa "/" en lugar de "/")
  ruta_carpeta <- "C:/Users/DELL/Downloads/Icfes_Raw"
  
  # 3. Obtener la lista de todos los archivos .txt
  archivos <- list.files(path = ruta_carpeta, pattern = "//.txt$", full.names = TRUE)
  
  # 4. Cargar y consolidar todos los archivos en una sola tabla
  icfes_consolidado <- rbindlist(
    lapply(archivos, function(archivo) {
      message("Cargando: ", basename(archivo))
      
      # fread auto-detecta separadores (| o ;) y codificación
      df <- fread(
        file = archivo,
        sep = "auto",
        encoding = "UTF-8",
        colClasses = "character", # Carga todo como texto para evitar errores de tipo entre años
        fill = TRUE
      )
      
      # Guardar el nombre del archivo origen para saber el periodo si no estuviera en las columnas
      df[, archivo_origen := basename(archivo)]
      
      return(df)
    }),
    use.names = TRUE,
    fill = TRUE
  )
  
  # 5. Convertir columnas numéricas de puntajes (ejemplo)
  columnas_puntajes <- c("PUNT_GLOBAL", "PUNT_LECTURA_CRITICA", "PUNT_MATEMATICAS", 
                         "PUNT_C_NATURALES", "PUNT_SOCIALES_CIUDADANAS", "PUNT_INGLES")
  
  # Convertir solo las columnas que existan en el dataset
  cols_a_convertir <- intersect(columnas_puntajes, names(icfes_consolidado))
  icfes_consolidado[, (cols_a_convertir) := lapply(.SD, as.numeric), .SDcols = cols_a_convertir]
  
  # Ver información del dataset final
  print(dim(icfes_consolidado))
  head(icfes_consolidado)
  
  
  # 2. Extraer el Año a partir de la columna 'periodo' (ej: '20181' -> '2018')
  icfes_consolidado[, anio := substr(periodo, 1, 4)]
  
  # 3. Convertir el puntaje global a numérico
  icfes_consolidado[, punt_global := as.numeric(punt_global)]
  
  # 4. Crear variables indicadoras (1 / 0 / NA) para calcular los % correctamente
  
  # % Internet (1 si es "Si", 0 si es "No", NA si está vacío)
  icfes_consolidado[, internet_val := fifelse(fami_tieneinternet == "Si", 1, 
                                              fifelse(fami_tieneinternet == "No", 0, NA_real_))]
  
  # % Horas de trabajo no remunerado (1 si tiene respuesta válida distinta de '0' o vacíos)
  icfes_consolidado[, trab_noremu_val := fifelse(!is.na(estu_horastrabnoremu) & 
                                                   !(trimws(estu_horastrabnoremu) %in% c("0", "0 horas", "Ninguna", "")), 1, 0)]
  
  # % Desplazamiento a colegio (1 si tiene registrado algún medio/tiempo de desplazamiento)
  icfes_consolidado[, desplaza_val := fifelse(!is.na(estu_desplazacolegio) & 
                                                !(trimws(estu_desplazacolegio) %in% c("0", "", "No")), 1, 0)]
  
  # 5. Agrupar por Sede, Año y Municipio
  icfes_resumen <- icfes_consolidado[
    , .(
      cant_estudiantes       = .N,
      prom_punt_global       = round(mean(punt_global, na.rm = TRUE), 2),
      pct_desplazacolegio    = round(mean(desplaza_val, na.rm = TRUE) * 100, 2),
      pct_horastrabnoremu    = round(mean(trab_noremu_val, na.rm = TRUE) * 100, 2),
      pct_fami_tieneinternet = round(mean(internet_val, na.rm = TRUE) * 100, 2)
    ),
    by = .(
      cole_cod_dane_sede,
      cole_nombre_sede,
      cole_depto_ubicacion,
      cole_mcpio_ubicacion,
      anio
    )
  ]
  
  # Ver el resultado
  head(icfes_resumen)
  
  write.csv(icfes_resumen, "C:/Users/DELL/OneDrive/Escritorio/UNIVERSIDAD/Maestria Business A/Proyecto Empresarial/Data/Raw/Enrichment/Icfes_Resumen.csv")
  