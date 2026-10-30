# ---- Paths ----
output_path <- "C:/Users/DELL/OneDrive/Escritorio/UNIVERSIDAD/Maestria Business A/Proyecto Empresarial/Data/Raw/C-600/2017/Sit_Acad_2017.csv"  # Change to your target path

# ---- General variables ----
df <- Situación_académica_al_finalizar_el_año_escolar_2016_según_educación_tradicional_por_grados_ciclos_y_jornada  # Replace with the name of your data frame in the environment

# ---- Execution ----
# Option 1: base R (semicolon separator, decimal point, UTF-8)
write.table(
  df,
  file = output_path,
  sep = ";",
  dec = ".",
  row.names = FALSE,
  na = "",
  fileEncoding = "UTF-8"
)


# CONVERSION BUT TXT -> CSV __________________________________________________________________________________


# ---- Paths ----
output_path <- "C:/Users/DELL/OneDrive/Escritorio/UNIVERSIDAD/Maestria Business A/Proyecto Empresarial/Data/Raw/C-600/2017/Ed_Tradicional_2017.csv"  # Change to your target path

# ---- General variables ----
df <- Alumnos.matriculados.en.educación.tradicional.y.CLEI.según.rangos.de.edad.por.jornada  # Replace with the name of your data frame in the environment


write.table(
  df,
  file = output_path,
  sep = ";",
  dec = ".",
  row.names = FALSE,
  na = "",
  quote = FALSE,
  fileEncoding = "UTF-8"
)

