# SkinColor_LATAM — Colorismo y logro educativo en Argentina

¿El color de piel predice el nivel educativo alcanzado en Argentina, condicional en el trasfondo del individuo? Análisis con LAPOP AmericasBarometer (Argentina 2004–2023), en la línea de Telles et al. (PERLA, 2015) — cuya muestra de 8 países no incluía a Argentina.

## Estructura

```
R/01_prepare_data.R        # limpieza y construcción de variables
R/02_models_argentina.R    # modelos M1-M6 + heterogeneidad (WLS cluster-UPM, probit ordenado)
docs/especificaciones_modelos.md    # documento vivo: specs, razonamiento y resultados
docs/especificaciones_modelos.docx  # ídem, versión Word
data/                      # NO versionado (ver abajo)
```

## Datos

Los microdatos de LAPOP no se redistribuyen. Descargar `Argentina_2004-2023_LAPOP_AmericasBarometer_v1.0_w.dta` desde [www.vanderbilt.edu/lapop](https://www.vanderbilt.edu/lapop/) y colocarlo en `data/`.

## Reproducir

```r
# Dependencias: haven, sandwich, lmtest, MASS
source("R/01_prepare_data.R")
source("R/02_models_argentina.R")
```

Resultados verificados contra una implementación independiente en Python (statsmodels): coincidencia al 4.º decimal.

## Resultado preliminar (v0.1)

Con el color evaluado por el encuestador (escala PERLA), la penalidad educativa en Argentina es chica e imprecisa (−0.13 años/SD, p≈0.10). El gradiente fuerte (−0.80, p<0.001) aparece solo con el color auto-reportado — una medida contaminada por estatus: los más educados se "auto-aclaran". Autoidentificarse blanco suma +0.79 años condicional en el tono observado. Detalle completo en `docs/especificaciones_modelos.md`.
