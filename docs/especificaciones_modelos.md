# Colorismo y logro educativo en Argentina — Documento vivo de especificaciones

**Proyecto:** SkinColor_LATAM · **Datos:** LAPOP AmericasBarometer, Argentina 2004–2023 (v1.0_w)
**Estado:** v0.1 — resultados preliminares (2026-07-18)
**Código:** `R/01_prepare_data.R` (limpieza) · `R/02_models_argentina.R` (modelos)

---

## 1. Pregunta

¿El color de piel predice el nivel educativo alcanzado en Argentina, condicional en el trasfondo del individuo? Es el test directo de la conclusión del proyecto previo de Data Science ("el color no importa por sí mismo, opera vía ingreso"), que el diseño anterior —variable importance de un random forest— no podía establecer: esa métrica no tiene signo, no es *ceteris paribus* y no distingue mediación de confusión.

Referencia comparada: Telles et al. (PERLA, 2015) encuentran penalidades de −0.38 a −0.71 años de escolaridad por desvío estándar de color en 8 países latinoamericanos. **Argentina no estaba en esa muestra**: este análisis aporta el dato faltante.

## 2. Datos y disponibilidad por ola

Archivo: `Argentina_2004-2023_LAPOP_AmericasBarometer_v1.0_w.dta` (N=13.527, 1.408 variables). Disponibilidad de las variables clave:

| Variable | Descripción | Olas disponibles |
|---|---|---|
| `colori` | Color de piel evaluado por el **encuestador** (PERLA 1–11) | 2010, 2012, 2014, 2017, 2019, 2023 |
| `colorr` | Color de piel **auto-reportado** (1–11) | ídem |
| `ed` | Años de educación (0–18) | 2008–2019 |
| `edre` | Nivel educativo ordinal (0–6) | solo 2023 |
| `ed2` | Nivel educativo de la madre (0–8) | 2012 (parcial), 2014, 2017 |
| `etid` | Autoidentificación étnica | todas menos 2021 |
| `wt`, `upm`, `estratopri` | Peso de diseño, conglomerado, región | todas |

La ola 2021 (telefónica, COVID) no tiene color ni educación → queda fuera. Esto dicta el diseño: **pooled 2010–2019 con `ed` (años) como outcome principal** y **2023 con `edre` como espejo ordinal**.

## 3. Decisiones de diseño y su razonamiento

**Muestra 25+.** La escolaridad debe estar completada; incluir 18–24 genera censura (aún no terminaron) y era la razón mecánica por la que `age` dominaba el random forest del proyecto anterior.

**Medida de tratamiento: `colori` (encuestador), no `colorr` (auto-reporte).** El auto-reporte está contaminado por estatus: en estos datos la correlación entre ambas medidas es apenas 0.32, y la brecha (auto − encuestador) pasa de +0.21 en el tercil educativo bajo a −0.25 en el alto — los más educados se "auto-aclaran". La evaluación del encuestador aproxima cómo te *perciben* (el mecanismo de la discriminación) y es el estándar PERLA/Telles. `colorr` se usa solo como contraste (M4).

**Controles pre-tratamiento únicamente:** cohorte de nacimiento (dummies por década, topes 1930/1990), sexo, urbano/rural, región (`estratopri`), ola. **Explícitamente excluidos:** ingreso actual, empleo formal, tamaño del hogar — son consecuencias de la educación (*bad controls*); condicionar en ellos "apaga" mecánicamente el efecto del color, que fue el error interpretativo del análisis previo. Los FE de región absorben que el NOA/NEA es a la vez más moreno y más pobre; los de cohorte absorben la expansión educativa secular.

**Diseño muestral:** pesos `wt` en todos los modelos WLS; errores estándar cluster por `upm` (LAPOP sortea conglomerados, no individuos). En 2023 `wt`=1 (muestra autoponderada) → probit ordenado sin pesos es correcto.

## 4. Especificaciones

Notación: `δ` = efectos fijos. Todos los WLS con pesos `wt` y SE cluster-UPM.

**M1 (principal).** WLS, pooled 2010–2019:

```
ed_i = β·colori_std_i + γ1·mujer_i + γ2·rural_i + δ_cohorte + δ_región + δ_ola + ε_i
```

β se lee como años de educación asociados a +1 SD de oscuridad de piel (≈1.5 puntos de la escala).

**M2 (color vs. categoría).** M1 + dummy `blanco` (etid=1). Horse race à la Telles: ¿pesa más el tono observado o la casilla con la que la persona se identifica?

**M3 (ordinal, 2023).** Probit ordenado sobre `edre` ∈ {0,…,6} con los mismos controles (sin δ_ola). Variable latente y umbrales estimados; respeta que las distancias entre niveles educativos no son iguales.

**M4 (medida endógena).** Idéntico a M1 reemplazando `colori_std` por `colorr_std`. La comparación M1 vs. M4 aísla el efecto de la *medida* (misma ecuación, misma muestra).

**M5 / M5b (origen socioeconómico).** M1 + FE de educación de la madre (`ed2`), submuestra 2012–2017. M5b re-estima M1 en la misma submuestra sin el control, para separar el efecto del control del efecto del cambio de muestra.

**M6 (funcional flexible).** M1 con bins: claro (1–3, ref.), medio (4–5), oscuro (6–11). Chequea no-linealidades (p. ej., penalidad concentrada en el extremo).

**MH (heterogeneidad).** M1 + `colori_std × joven` (nacidos ≥1975): ¿se atenúa el gradiente entre generaciones?

## 5. Resultados preliminares (v0.1)

| Modelo | Muestra | N | Coef. color | SE | p |
|---|---|---|---|---|---|
| M1: `colori_std` | pooled 2010–19 | 5.807 | −0.135 | 0.083 | 0.104 |
| M2: `colori_std` / `blanco` | pooled | 5.528 | −0.121 / **+0.788** | 0.083 / 0.133 | 0.142 / <0.001 |
| M3: probit ord. `edre` | 2023 | 1.217 | −0.043 | 0.047 | 0.362 |
| M4: `colorr_std` | pooled | 5.806 | **−0.801** | 0.061 | <0.001 |
| M5: `colori_std` + madre | 2012–17 | 2.751 | −0.106 | 0.071 | 0.134 |
| M5b: sin control madre | 2012–17 | 2.751 | −0.072 | 0.099 | 0.467 |
| M6: medio / oscuro | pooled | 5.807 | −0.259 / −0.302 | 0.199 / 0.323 | 0.194 / 0.350 |
| MH: interacción × joven | pooled | 5.807 | +0.049 | 0.094 | 0.605 |

Descriptivo ponderado (años de educación, 25+, 2010–2019): claro 10.71 · medio 10.17 · oscuro 10.15.

**Lectura preliminar.**

1. Con la medida del encuestador, la penalidad de color en Argentina es chica e imprecisa (−0.13 años/SD, p≈0.10) — muy por debajo del rango PERLA (−0.38 a −0.71). El IC es consistente con cero y con efectos de hasta ~−0.3.
2. El contraste M1 vs. M4 (−0.13 vs. −0.80) es el hallazgo central: el gradiente fuerte aparece solo con la medida contaminada por estatus. Mecanismo visible en los datos: los educados se auto-reportan más claros de lo que los ve el encuestador.
3. La categoría le gana al color: autoidentificarse blanco suma +0.79 años condicional en el tono observado. La frontera simbólica "blanco/no blanco" parece más operativa que el gradiente cromático — consistente con la tesis del crisol que abolió la raza sin abolir la jerarquía.
4. Sin atenuación por cohorte; el control por educación de la madre no altera nada (aunque esa submuestra ya venía sin efecto: test débil).

## 6. Caveats

Distribución de `colori` truncada (solo ~6% con 6+; 377 obs. en el bin oscuro) → poca potencia en el extremo. La evaluación del encuestador puede incorporar señales de estatus del entrevistado (sesgo *hacia* encontrar efecto — y aun así casi no lo hay). No hay ID de entrevistador en el merge para FE de entrevistador. `ed2` solo en 3 olas.

## 7. Agenda

1. Pooled sudamericano con el Grand Merge (FE de país + interacciones país × color) para poner el coeficiente argentino en contexto regional.
2. FE de entrevistador si conseguimos el ID (archivos por ola).
3. Outcomes alternativos: secundario completo (dummy), acceso a terciario/universitario.
4. Sección de mecanismo: formalizar el análisis de auto-aclaramiento (gap auto−encuestador como outcome).

## Changelog

- **v0.1 (2026-07-18).** Diseño acordado, M1–M6 + MH estimados en Python y replicados en R (coincidencia al 4.º decimal). Documento inicial.
