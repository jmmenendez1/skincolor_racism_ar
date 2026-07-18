# ------------------------------------------------------------------
# 03_models_southamerica.R
# Comparativa sudamericana a la Telles/PERLA: penalidad educativa del
# color de piel por país, pooled con interacciones, horse race
# color vs. categoría, y mecanismo de auto-aclaramiento.
# Insumo: data/sudamerica_subset.dta (subset del Grand Merge LAPOP
# 2004-2023 con 17 columnas; ver README).
# ------------------------------------------------------------------

library(haven)
library(sandwich)
library(lmtest)

d <- read_dta("data/sudamerica_subset.dta")
d[] <- lapply(d, function(x) as.numeric(zap_missing(x)))

nombres <- c(`8`="COL", `9`="ECU", `10`="BOL", `11`="PER", `12`="PRY",
             `13`="CHL", `14`="URY", `15`="BRA", `16`="VEN", `17`="ARG",
             `24`="GUY", `27`="SUR")
d$country <- nombres[as.character(d$pais)]

s <- d[!is.na(d$q2) & d$q2 >= 25, ]
s$female     <- ifelse(is.na(s$q1), NA, as.numeric(s$q1 == 2))
s$rural      <- ifelse(is.na(s$ur), NA, as.numeric(s$ur == 2))
s$cohort_dec <- pmin(pmax(floor((s$year - s$q2) / 10) * 10, 1930), 1990)
s$white      <- ifelse(is.na(s$etid), NA, as.numeric(s$etid == 1))
s$reg        <- s$pais * 10000 + s$estratopri   # región anidada en país

POOLED_SD <- sd(s$colori, na.rm = TRUE)  # para expresar efectos por SD comparable
cat("SD pooled de colori:", round(POOLED_SD, 3), "\n\n")

FORM <- ed ~ colori + female + rural + factor(cohort_dec) + factor(reg) + factor(year)

# --- 1) Espejo de M1 país por país ---------------------------------
# colori entra en escala cruda 1-11 (efecto por punto); reportamos
# también el efecto por SD *pooled* para comparabilidad entre países.
cc <- c("ed", "colori", "female", "rural", "cohort_dec", "reg", "upm", "wt", "year")
res <- do.call(rbind, lapply(split(s, s$country), function(g) {
  g <- g[complete.cases(g[, cc]), ]
  if (nrow(g) < 1000) return(NULL)
  m  <- lm(FORM, data = g, weights = wt)
  ct <- coeftest(m, vcov = vcovCL(m, cluster = g$upm))
  b  <- ct["colori", 1]; se <- ct["colori", 2]
  data.frame(country = g$country[1], N = nobs(m),
             b_punto = b, se = se, p = ct["colori", 4],
             b_sd = b * POOLED_SD,
             ci_lo = (b - 1.96 * se) * POOLED_SD,
             ci_hi = (b + 1.96 * se) * POOLED_SD)
}))
res <- res[order(res$b_sd), ]
cat("=== Penalidad de color por país (por punto y por SD pooled) ===\n")
print(res, row.names = FALSE, digits = 3)
write.csv(res, "output/sa_bycountry.csv", row.names = FALSE)

# --- 2) Pooled con interacciones país x color (base: ARG) -----------
# weight1500 estandariza el tamaño muestral de cada país-ola.
p <- s[complete.cases(s[, c(cc[-8], "weight1500", "country")]), ]
p$country <- relevel(factor(p$country), ref = "ARG")
mp <- lm(ed ~ colori * country + female + rural + factor(cohort_dec) +
           factor(reg) + factor(year), data = p, weights = weight1500)
ctp <- coeftest(mp, vcov = vcovCL(mp, cluster = p$upm))
keep <- grepl("^colori", rownames(ctp))
cat("\n=== Pooled: colori (base ARG) + interacciones ===\n")
print(round(ctp[keep, ], 3))

# --- 3) Horse race por país: color observado vs. blanco -------------
cc2 <- c(cc, "white")
cat("\n=== Horse race: coef colori | coef blanco ===\n")
hr <- do.call(rbind, lapply(split(s, s$country), function(g) {
  g <- g[complete.cases(g[, cc2]), ]
  if (nrow(g) < 1000) return(NULL)
  m  <- lm(update(FORM, . ~ . + white), data = g, weights = wt)
  ct <- coeftest(m, vcov = vcovCL(m, cluster = g$upm))
  data.frame(country = g$country[1], N = nobs(m),
             b_color = ct["colori", 1], p_color = ct["colori", 4],
             b_white = ct["white", 1],  p_white = ct["white", 4])
}))
print(hr, row.names = FALSE, digits = 3)

# --- 4) Mecanismo: auto-aclaramiento por país -----------------------
# Brecha (auto-reporte - encuestador) por tercil educativo.
cat("\n=== Auto-aclaramiento: gap tercil alto - tercil bajo ===\n")
aw <- do.call(rbind, lapply(split(s, s$country), function(g) {
  g <- g[complete.cases(g[, c("colori", "colorr", "ed")]), ]
  if (nrow(g) < 1000) return(NULL)
  g$gap <- g$colorr - g$colori
  qs  <- unique(quantile(g$ed, probs = seq(0, 1, 1/3)))
  ter <- cut(g$ed, breaks = qs, include.lowest = TRUE)
  gm  <- tapply(g$gap, ter, mean)
  data.frame(country = g$country[1],
             corr = cor(g$colori, g$colorr),
             gap_bajo = gm[1], gap_alto = gm[length(gm)],
             dif = gm[length(gm)] - gm[1])
}))
print(aw[order(aw$dif), ], row.names = FALSE, digits = 3)

# --- 5) Sensibilidad (reconciliación con PERLA) ---------------------
# Coef de colori con/sin FE de región y solo ola 2010, países clave.
cat("\n=== Sensibilidad: con/sin FE región, pooled vs. 2010 ===\n")
for (c0 in c("BRA", "BOL", "URY", "ARG")) {
  g <- s[s$country == c0, ]
  for (spec in list(
    list(lab = "pooled, con region FE", d = g,               f = FORM),
    list(lab = "pooled, sin region FE", d = g,               f = ed ~ colori + female + rural + factor(cohort_dec) + factor(year)),
    list(lab = "solo 2010, sin region", d = g[g$year == 2010, ], f = ed ~ colori + female + rural + factor(cohort_dec)))) {
    v <- intersect(all.vars(spec$f), names(spec$d))
    dd <- spec$d[complete.cases(spec$d[, c(v, "upm", "wt")]), ]
    if (nrow(dd) < 800) next
    m  <- lm(spec$f, data = dd, weights = wt)
    ct <- coeftest(m, vcov = vcovCL(m, cluster = dd$upm))
    cat(sprintf("%s | %-22s b=%+.3f (p=%.3f, N=%d)\n",
                c0, spec$lab, ct["colori", 1], ct["colori", 4], nobs(m)))
  }
}
