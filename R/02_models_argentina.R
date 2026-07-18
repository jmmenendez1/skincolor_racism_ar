# ------------------------------------------------------------------
# 02_models_argentina.R
# Estima los modelos M1-M6 + heterogeneidad por cohorte.
# WLS con pesos de diseño (wt) y SE cluster por UPM; probit ordenado
# para la ola 2023. Ver docs/especificaciones_modelos.md para el
# razonamiento detrás de cada especificación.
# ------------------------------------------------------------------

library(sandwich)
library(lmtest)
library(MASS)

s <- readRDS("data/arg_clean.rds")

POOL_YEARS <- c(2010, 2012, 2014, 2017, 2019)  # olas con colori y ed (años)
pool <- s[s$year %in% POOL_YEARS, ]

CONTROLS <- "female + rural + factor(cohort_dec) + factor(estratopri) + factor(year)"

# Helper: WLS + SE cluster UPM; imprime solo coeficientes de interés --
run_wls <- function(rhs, data, label, show) {
  f <- as.formula(paste("ed ~", rhs, "+", CONTROLS))
  vv <- intersect(all.vars(f), names(data))
  d  <- data[complete.cases(data[, c(vv, "upm", "wt")]), ]
  m  <- lm(f, data = d, weights = wt)
  ct <- coeftest(m, vcov = vcovCL(m, cluster = d$upm))
  cat("\n===", label, "| N =", nobs(m), "===\n")
  print(round(ct[rownames(ct) %in% show, , drop = FALSE], 4))
  invisible(list(model = m, ct = ct, n = nobs(m)))
}

# --- M1: años de educación ~ color del encuestador (principal) ------
m1 <- run_wls("colori_std", pool,
              "M1: ed ~ colori_std (pooled 2010-2019)",
              c("colori_std", "female", "rural"))

# --- M2: horse race color observado vs. autoidentificación blanca ---
m2 <- run_wls("colori_std + white", pool,
              "M2: M1 + dummy blanco (etid)",
              c("colori_std", "white", "female", "rural"))

# --- M4: color auto-reportado (medida endógena, para contraste) -----
m4 <- run_wls("colorr_std", pool,
              "M4: ed ~ colorr_std (auto-reporte)",
              c("colorr_std", "female", "rural"))

# --- M6: bins de color (funcional flexible; ref = claro 1-3) --------
m6 <- run_wls("medio + oscuro", pool,
              "M6: bins de color",
              c("medio", "oscuro", "female", "rural"))

# --- M5/M5b: control por educación de la madre (solo 2012-2017) -----
mad <- pool[!is.na(pool$ed2), ]
m5  <- run_wls("colori_std + factor(ed2)", mad,
               "M5: + educ. de la madre (2012-2017)", c("colori_std"))
m5b <- run_wls("colori_std", mad,
               "M5b: misma muestra sin control madre", c("colori_std"))

# --- Heterogeneidad: ¿se atenúa el gradiente entre cohortes? --------
mh <- run_wls("colori_std * joven", pool,
              "MH: interacción color x cohorte joven (1975+)",
              c("colori_std", "joven", "colori_std:joven"))

# --- M3: probit ordenado sobre edre, ola 2023 -----------------------
# wt == 1 para toda la muestra AR 2023 (autoponderada) -> sin pesos.
d23 <- s[s$year == 2023, ]
d23 <- d23[complete.cases(d23[, c("edre", "colori_std", "female", "rural",
                                  "cohort_dec", "estratopri")]), ]
m3 <- polr(factor(edre, ordered = TRUE) ~ colori_std + female + rural +
             factor(cohort_dec) + factor(estratopri),
           data = d23, method = "probit", Hess = TRUE)
ct3 <- coeftest(m3)
cat("\n=== M3: probit ordenado edre (2023) | N =", nrow(d23), "===\n")
print(round(ct3[c("colori_std", "female", "rural"), ], 4))

# --- Mecanismo: auto-aclaramiento por estatus educativo -------------
x <- pool[complete.cases(pool[, c("colori", "colorr", "ed")]), ]
x$gap    <- x$colorr - x$colori
x$ed_ter <- cut(x$ed, breaks = quantile(x$ed, probs = seq(0, 1, 1/3)),
                include.lowest = TRUE, labels = c("baja", "media", "alta"))
cat("\ncorr(colori, colorr):", round(cor(x$colori, x$colorr), 3), "\n")
cat("Brecha (auto - encuestador) por tercil educativo:\n")
print(round(tapply(x$gap, x$ed_ter, mean), 3))
