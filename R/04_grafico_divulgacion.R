# ------------------------------------------------------------------
# 04_grafico_divulgacion.R
# Gráfico de la pieza de divulgación: "El tono importa poco;
# creerse blanco, mucho". Dos paneles con valores AJUSTADOS
# (g-computation sobre el WLS): educación esperada de personas
# comparables según (a) tono de piel visto por el encuestador y
# (b) autoidentificación en la casilla "blanco".
# Genera versión en español (_es) y en inglés (_en); editá los
# textos en la lista TXT de abajo.
# Requiere: data/arg_clean.rds (correr antes R/01_prepare_data.R)
# Nota: en sistemas con locale no-UTF8, correr con LC_ALL=C.UTF-8
# ------------------------------------------------------------------

library(ggplot2)

s <- readRDS("data/arg_clean.rds")
pool <- s[s$year %in% c(2010, 2012, 2014, 2017, 2019), ]
pool$bin <- cut(pool$colori, breaks = c(0, 3, 5, 11),
                labels = c("claro", "medio", "oscuro"))

vars <- c("ed", "bin", "white", "female", "rural", "cohort_dec",
          "estratopri", "upm", "wt", "year")
d <- pool[complete.cases(pool[, vars]), ]

# --- Modelo y valores ajustados (g-computation) --------------------
m <- lm(ed ~ bin + white + female + rural + factor(cohort_dec) +
          factor(estratopri) + factor(year), data = d, weights = wt)

margen <- function(var, val) {
  dd <- d
  dd[[var]] <- if (var == "bin") factor(val, levels = levels(d$bin)) else val
  weighted.mean(predict(m, newdata = dd), d$wt)
}

adj_tono    <- sapply(c("claro", "medio", "oscuro"), function(v) margen("bin", v))
adj_casilla <- sapply(c(0, 1), function(v) margen("white", v))
cat("Ajustados tono:",    round(adj_tono, 2),    "\n")
cat("Ajustados casilla:", round(adj_casilla, 2), "\n")

# --- Textos ES / EN (editar acá) -----------------------------------
TXT <- list(
  es = list(
    titulo    = "El tono importa poco; creerse blanco, mucho",
    subtitulo = "Educación esperada de personas comparables, Argentina, adultos 25+ — LAPOP 2010–2019",
    eje_y     = "Años de educación esperados",
    panel_a   = "…según el tono de piel\n(lo que ve el encuestador)",
    panel_b   = "…según la casilla étnica\n(cómo se identifica la persona)",
    tonos     = c("claro\n(1–3)", "medio\n(4–5)", "oscuro\n(6–11)"),
    casillas  = c("no se identifica\nblanco", "se identifica\nblanco"),
    brechas   = c("0.3 años", "0.8 años"),
    nota      = paste("Personas comparables: misma generación, sexo, región, entorno urbano/rural y año de encuesta; cada panel",
                      "mantiene fijo, además, lo que mide el otro (casilla / tono).",
                      "Valores ajustados por regresión ponderada; escala de tonos PERLA de 11 puntos.", sep = "\n")
  ),
  en = list(
    titulo    = "Skin tone matters little; thinking of yourself as white, a lot",
    subtitulo = "Expected schooling of comparable individuals, Argentina, adults 25+ — LAPOP 2010–2019",
    eje_y     = "Expected years of schooling",
    panel_a   = "…by skin tone\n(as rated by the interviewer)",
    panel_b   = "…by ethnic self-identification\n(how the person identifies)",
    tonos     = c("light\n(1–3)", "medium\n(4–5)", "dark\n(6–11)"),
    casillas  = c("does not identify\nas white", "identifies\nas white"),
    brechas   = c("0.3 years", "0.8 years"),
    nota      = paste("Comparable individuals: same birth cohort, sex, region, urban/rural setting and survey year; each panel",
                      "additionally holds fixed what the other measures (category / tone).",
                      "Regression-adjusted values (design weights); 11-point PERLA skin-tone scale.", sep = "\n")
  )
)

# --- Colores -------------------------------------------------------
INK <- "#1F2937"; MUT <- "#6B7280"; SURF <- "#fcfcfb"; AZUL <- "#2563EB"
PERLA <- c("#e9c1b7", "#c0a280", "#85674f")   # representantes de cada bin

# --- Construcción del gráfico -------------------------------------
hacer_grafico <- function(t) {
  df <- data.frame(
    panel = factor(rep(c("a", "b"), c(3, 2)), labels = c(t$panel_a, t$panel_b)),
    x     = c(t$tonos, t$casillas),
    orden = c(1:3, 1:2),
    y     = c(adj_tono, adj_casilla),
    col   = c(PERLA, AZUL, AZUL)
  )
  brechas <- data.frame(
    panel = factor(c("a", "b"), labels = c(t$panel_a, t$panel_b)),
    x = c(3.42, 2.42), ymin = c(adj_tono[3], adj_casilla[1]),
    ymax = c(adj_tono[1], adj_casilla[2]),
    lab = t$brechas, colr = c(MUT, AZUL)
  )
  ggplot(df, aes(reorder(x, orden), y, group = 1)) +
    facet_wrap(~panel, scales = "free_x") +
    geom_line(color = "#D1D5DB", linewidth = 0.6) +
    geom_point(aes(fill = I(col)), shape = 21, size = 5.5,
               color = INK, stroke = 0.6) +
    geom_text(aes(label = sprintf("%.1f", y)), vjust = -1.4,
              size = 3.6, fontface = "bold", color = INK) +
    geom_segment(data = brechas, aes(x = x, xend = x, y = ymin, yend = ymax),
                 inherit.aes = FALSE, color = MUT, linewidth = 0.4) +
    geom_text(data = brechas, aes(x = x + 0.12, y = (ymin + ymax) / 2,
                                  label = lab, color = I(colr)),
              inherit.aes = FALSE, hjust = 0, size = 3.2, fontface = "bold") +
    scale_y_continuous(limits = c(9.7, 11.3)) +
    coord_cartesian(clip = "off") +
    labs(title = t$titulo, subtitle = t$subtitulo, x = NULL,
         y = t$eje_y, caption = t$nota) +
    theme_minimal(base_size = 11) +
    theme(
      plot.background   = element_rect(fill = SURF, color = NA),
      panel.grid.minor  = element_blank(),
      panel.grid.major.x = element_blank(),
      panel.grid.major.y = element_line(color = "#EDEDEB", linewidth = 0.4),
      plot.title        = element_text(face = "bold", size = 15, color = INK),
      plot.subtitle     = element_text(size = 9.5, color = MUT),
      plot.caption      = element_text(size = 7, color = MUT, hjust = 0),
      strip.text        = element_text(size = 10.5, color = INK),
      axis.text         = element_text(color = INK),
      plot.margin       = margin(10, 55, 8, 10)
    )
}

for (lang in names(TXT)) {
  g <- hacer_grafico(TXT[[lang]])
  ggsave(sprintf("output/grafico_divulgacion_%s.png", lang), g,
         width = 8.8, height = 5.2, dpi = 150, bg = SURF,
         device = grDevices::png, type = "cairo")
  cat("Guardado output/grafico_divulgacion_", lang, ".png\n", sep = "")
}
