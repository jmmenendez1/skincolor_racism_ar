# ------------------------------------------------------------------
# 01_prepare_data.R
# Proyecto: Colorismo y logro educativo en Argentina (LAPOP 2004-2023)
# Lee el .dta de LAPOP, construye las variables del análisis y guarda
# un .rds limpio. Los datos NO se versionan (ver .gitignore): bajarlos
# de www.vanderbilt.edu/lapop y ponerlos en data/.
# ------------------------------------------------------------------

library(haven)

DATA_RAW <- "data/Argentina_2004-2023_LAPOP_AmericasBarometer_v1.0_w.dta"
DATA_OUT <- "data/arg_clean.rds"

vars <- c("year", "colorr", "colori", "etid", "ed", "edre", "ed2",
          "q2", "q1", "q1tc_r", "ur", "estratopri", "upm", "wt")

df <- read_dta(DATA_RAW, col_select = all_of(vars))
df[] <- lapply(df, function(x) as.numeric(zap_missing(x)))

# --- Género: q1 (olas 2008-2019) / q1tc_r (2023; excluimos categoría 3
#     "no se identifica" por N insuficiente para estimar) -------------
df$female <- ifelse(!is.na(df$q1), as.numeric(df$q1 == 2),
             ifelse(df$q1tc_r %in% c(1, 2), as.numeric(df$q1tc_r == 2), NA))

# --- Ruralidad ----------------------------------------------------
df$rural <- ifelse(is.na(df$ur), NA, as.numeric(df$ur == 2))

# --- Edad y cohorte de nacimiento ---------------------------------
# Década de nacimiento con topes en 1930 y 1990 para evitar celdas vacías.
df$age        <- df$q2
df$cohort     <- df$year - df$age
df$cohort_dec <- pmin(pmax(floor(df$cohort / 10) * 10, 1930), 1990)

# --- Etnicidad: dummy de autoidentificación blanca ----------------
df$white <- ifelse(is.na(df$etid), NA, as.numeric(df$etid == 1))

# --- Muestra de análisis: 25+ (educación completada) --------------
s <- df[!is.na(df$age) & df$age >= 25, ]

# --- Color de piel estandarizado (media 0, sd 1 sobre la muestra 25+)
#     colori = evaluación del ENCUESTADOR (escala PERLA 1-11)
#     colorr = auto-reporte del encuestado
s$colori_std <- as.numeric(scale(s$colori))
s$colorr_std <- as.numeric(scale(s$colorr))

# --- Bins de color (ref: claro 1-3) -------------------------------
s$medio  <- ifelse(is.na(s$colori), NA, as.numeric(s$colori >= 4 & s$colori <= 5))
s$oscuro <- ifelse(is.na(s$colori), NA, as.numeric(s$colori >= 6))

# --- Cohorte joven (nacidos 1975+) para heterogeneidad ------------
s$joven <- as.numeric(s$cohort >= 1975)

saveRDS(s, DATA_OUT)
cat("Guardado", DATA_OUT, "- N (25+):", nrow(s), "\n")
