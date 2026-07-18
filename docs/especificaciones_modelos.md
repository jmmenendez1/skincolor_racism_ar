# Colorismo y logro educativo en Argentina — Documento vivo de especificaciones

**Proyecto:** SkinColor_LATAM · **Datos:** LAPOP AmericasBarometer 2004–2023 (Argentina + Sudamérica)
**Estado:** v0.2 — Argentina + comparativa sudamericana (2026-07-18)
**Código:** `R/01_prepare_data.R` · `R/02_models_argentina.R` · `R/03_models_southamerica.R`

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

## 7. Comparativa sudamericana à la Telles (v0.2)

**Datos:** subset del Grand Merge (`data/sudamerica_subset.dta`): 12 países, olas 2010–2019 con `colori` y `ed`, ~76.000 obs. 25+. **Especificación:** espejo exacto de M1 por país, con `colori` en escala cruda 1–11 (efecto por punto) — estandarizar dentro de cada país mezclaría diferencias de efecto con diferencias de varianza del color. Para comparabilidad se reporta también el efecto por SD *pooled* (1.69 puntos). Pooled con `weight1500` (estandariza cada país-ola) e interacciones país × color con base Argentina. Código: `R/03_models_southamerica.R`. Figura: `output/coefplot_sudamerica.png`.

### 7.1 Penalidad de color por país (años de educación por +1 SD pooled)

| País | N | β/SD | IC 95% | p |
|---|---|---|---|---|
| Uruguay | 6.524 | **−0.71** | [−0.92, −0.50] | <0.001 |
| Bolivia | 9.547 | **−0.53** | [−0.76, −0.30] | <0.001 |
| Surinam | 5.527 | **−0.29** | [−0.46, −0.12] | 0.001 |
| Ecuador | 6.955 | **−0.27** | [−0.45, −0.08] | 0.006 |
| Argentina | 5.807 | −0.16 | [−0.35, +0.03] | 0.104 |
| Perú | 6.807 | −0.09 | [−0.27, +0.09] | 0.313 |
| Colombia | 5.893 | −0.01 | [−0.16, +0.14] | 0.903 |
| Venezuela | 5.002 | −0.00 | [−0.15, +0.15] | 0.995 |
| Paraguay | 5.858 | +0.02 | [−0.12, +0.17] | 0.736 |
| Brasil | 6.521 | +0.06 | [−0.06, +0.18] | 0.295 |
| Chile | 7.157 | +0.09 | [−0.07, +0.26] | 0.274 |
| Guyana | 4.770 | +0.15 | [−0.00, +0.30] | 0.052 |

Pooled con interacciones (base ARG): la penalidad argentina difiere significativamente de Uruguay (−0.31 por punto, p<0.001), Bolivia (−0.27, p=0.002) y Surinam (−0.22, p=0.005) por un lado, y de Chile (+0.15, p=0.038), Guyana (+0.17, p=0.022) y Paraguay (+0.14, p=0.047) por el otro. Argentina está literalmente en el medio de la distribución regional.

### 7.2 Horse race color vs. categoría, por país

El patrón argentino ("la categoría le gana al color") **no** es peculiaridad nuestra: el premio por autoidentificarse blanco condicional en el tono observado es grande y significativo en Bolivia (+1.37 años), Uruguay (+1.17), Brasil (+0.89), Argentina (+0.79) y Venezuela (+0.69). Pero en Bolivia, Uruguay, Ecuador y Surinam el color *también* sobrevive con la categoría en la ecuación — en Argentina no. El caso argentino se distingue por ser casi puramente categorial.

### 7.3 Mecanismo: auto-aclaramiento por país

Diferencia del gap (auto − encuestador) entre tercil educativo alto y bajo: Brasil −0.81, Bolivia −0.73, Paraguay −0.60, Venezuela −0.52, **Argentina −0.47**, …, Uruguay −0.09, Guyana +0.00. La hipótesis previa (Argentina como caso extremo de auto-aclaramiento) **no se sostiene**: Brasil y Bolivia muestran más. Patrón sugerente: Uruguay, el país con mayor penalidad de color, es donde menos se "auto-aclara" la gente — donde el gradiente es más real, menos se negocia la autopercepción. A formalizar.

### 7.4 Discrepancia con PERLA — abierta

Nuestros nulos de Brasil (+0.06) y Colombia (−0.01) contrastan con los −0.5 y −0.39 de Telles et al. (2015). La sensibilidad muestra que **no** lo explican ni los FE de región ni el pooling de olas (Brasil da ~0 también sin FE de región y en 2010 solo). Diferencias restantes con su diseño: ellos usan la ronda PERLA 2010 con controles de origen de clase (ocupación parental) y su propia armonización de escolaridad. Pendiente: conseguir sus archivos de replicación. Hasta resolver esto, la comparación con "el rango PERLA" debe citarse con esta nota.

### 7.5 Lectura

La penalidad de color argentina (−0.16 ns) es mediana en la región, no excepcional. Lo distintivo de Argentina es la *forma* del racismo: puramente categorial (blanco/no blanco) y con la señal cromática debilitada — consistente con el argumento histórico del crisol. Y el hallazgo regional inesperado es **Uruguay**: la mayor penalidad de color de Sudamérica en el país más "blanco" de la muestra, con poco auto-aclaramiento. Eso merece paper propio.

## 8. Caveats adicionales (v0.2)

Guyana y Surinam tienen composiciones étnicas (indo-descendientes, cimarrones) donde la escala clara→oscura captura otra cosa que en el resto; sus coeficientes no son directamente comparables. El premio blanco de Guyana (+5.68) sale de un N minúsculo de autoidentificados blancos. Venezuela 2016 en contexto de crisis. `estratopri` cambia de definición entre olas en algunos países (FE conservador igual).

## 9. Agenda

1. ~~Pooled sudamericano~~ **Hecho (v0.2).**
2. Conseguir archivos de replicación de Telles et al. (2015) para resolver la discrepancia de Brasil/Colombia (§7.4).
3. FE de entrevistador si conseguimos el ID (archivos por ola).
4. Outcomes alternativos: secundario completo (dummy), acceso a terciario/universitario.
5. Formalizar el auto-aclaramiento (gap como outcome; correlación agregada penalidad × auto-aclaramiento, §8.3).
6. Profundizar Uruguay (¿por qué la mayor penalidad regional?) — posible extensión o paper aparte.

## Changelog

- **v0.2 (2026-07-18).** Comparativa sudamericana: 12 países, espejo de M1 por país, pooled con interacciones, horse race y auto-aclaramiento comparado. Python replicado en R. Figura `output/coefplot_sudamerica.png`. Discrepancia con PERLA documentada como abierta.
- **v0.1 (2026-07-18).** Diseño acordado, M1–M6 + MH estimados en Python y replicados en R (coincidencia al 4.º decimal). Documento inicial.
