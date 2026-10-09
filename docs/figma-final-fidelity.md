# Figma definitivo: implementación y evidencia

Rama `feature/figma-final-fidelity`, baseline `d461212`. No hubo commit, push, PR o merge.

## Referencia verificada

Se reutilizaron las referencias locales ya inspeccionadas: `desing/references/figma-final.mp4`, `desing/references/contact.jpg` y los fotogramas de `artifacts/figma-reference-inspection/`. No se volvió a investigar el enlace Figma. El diseño ahora sí es una referencia visual observada; el primer acabado previo sin acceso al video fue reemplazado donde difería del diseño aprobado.

La implementación reproduce composición y jerarquía verificables del video, con la paleta indicada por el usuario: azul #1769E0, marino #10233F, verde #16865C, naranja #C27613, rojo #D83B46 y blanco #FFFFFF. Tipografía compacta, superficies claras, bordes finos, radios suaves. El marco del teléfono, notch, UI de Figma/OBS y datos de demostración no se incorporan al producto.

## Matriz de las nueve vistas

| Vista | Implementado desde la referencia | Diferencias restantes / justificadas |
|---|---|---|
| Inicio/mapa | Header blanco compacto, marca de ruta azul, avatar real, controles laterales, entrada inferior compacta con Analítica/Validación/Reportar y búsqueda | El mapa es OpenStreetMap real; no se copia la ilustración/cartografía ficticia. Validación está deshabilitada hasta disponer de una evaluación real |
| Planificador | Origen/destino apilados, Ahora/Programar sobre fondo segmentado, cuadrícula 2×2 de modos, borde seleccionado y CTA azul | GPS conserva origen real y acceso a cambio manual; walking se etiqueta A pie. No se marca Disponible antes de recibir ruta |
| Programar | Campos visuales de fecha y hora con los selectores nativos existentes, tarjeta histórica, advertencia sin predicción | La tarjeta conserva muestra, periodo y limitaciones reales, por lo que contiene más metadatos que el demo. Ambos campos reutilizan el flujo de selección existente |
| Resultados | Tarjeta sugerida con borde azul, duración destacada, distancia/razones/incidentología cuando hay evidencia, alternativas, ruta seleccionada separada y CTA condicional | Se mantienen controles de modificación y detalle, proveedores/atribución y advertencias reales. No se inventa nombre de avenida ni duración del prototipo |
| Reportar | Mapa de fondo con marcador rojo de la coordenada real del borrador, sheet blanco, seis categorías reales en 3×2, descripción y publicar/preparar según capacidad, estados existentes | Límite real de descripción 200, no 140 del demo. El marcador se etiqueta sin publicar. Se conservan cambio de ubicación y borrador/errores |
| Analítica | Selector temporal real, resumen marino, barras verticales de franjas reales, categorías y cobertura | 24/7/30 franjas según el periodo real, no número de barras o porcentajes del demo. Las métricas adicionales quedan accesibles debajo del gráfico |
| Validación | Resumen marino de criterios evaluables reales, leyenda PASS/FAIL/UNKNOWN/NOT_APPLICABLE, lista de criterios | El denominador excluye desconocidos/no aplicables. El color no convierte UNKNOWN en PASS; se mantienen explicación y evidencia reales |
| Perfil | Avatar, sesión verificable, proveedor de cuenta, último estado de ubicación, preferencias reales, información de cuenta expandible, acerca/privacidad y salida roja | No se inventan permisos activos ni autenticación Google. Permisos muestran el último estado observado, no una consulta nueva. Se conserva rol/estado real en detalle |
| Menú lateral | Fondo marino, marca compacta, grupos MOVILIDAD/EVIDENCIA/CUENTA, selección resaltada, accesos reales | No se copian Producto/Foundations/Components ni pantallas demo inexistentes. Se conserva Puntos cercanos y Administración según permisos |

## Preservación funcional

No se modificaron servicios, proveedores, SQL/RLS, repositorios, controladores, modelos, Navigation V2, motores, criterios de suficiencia o validación ni dependencias. Login y OAuth conservan sus métodos. Las lecturas de sesión/proveedor en Perfil usan el cliente existente sin nuevas consultas. La salida roja reutiliza la confirmación/signOut actual de Home.

La entrada compacta de Home abre el mismo MapSearchPanel; el panel conserva origen/destino, selección manual, routing y recomendaciones. Los accesos de validación se habilitan con el contexto existente y evalúan al abrir, sin decisiones nuevas ni routing. Reportar reutiliza publicación/cambio de ubicación existentes; el marcador solo dibuja su dato ya disponible.

`initiallyCollapsed` es una opción de composición: producción inicia compacta como el video; los tests de operaciones existentes declaran inicio expandido. La matriz visual comprueba también el inicio compacto real. En planificación expandida se permite hasta 68 % de altura; con teclado/aviso de perfil se reduce para preservar acceso al mapa y alertas. La versión compacta deja la mayor parte del mapa visible y adapta accesos para texto grande.

## Problemas encontrados y corregidos

- Overflow del gráfico en texto 2×: altura escalable y barras adaptadas al ancho; valores exactos disponibles en tooltip/semántica y detalle. La altura es relativa al máximo observado, no tráfico.
- Overlay del panel sobre avisos/controles: límite adaptado, acción Reportar trasladada al header de la hoja, respetando callback.
- Tests que operaban el planificador cerrado: escenarios de operación explícitos y cobertura separada del inicio compacto.
- Menú/cuenta lazy y elementos fuera del viewport: scrollUntilVisible con scope y espera antes del tap; no warnIfMissed false.
- Duración visible en sugerida y seleccionada: assertions precisas sobre la tarjeta correspondiente, sin eliminar valores legítimos.
- Detalle de cuenta fuera del viewport: apertura y comprobación de la sección real, manteniendo nombre/correo/rol/estado.
- Labels de estado conservan significado y colores; textos de criterios mantienen contraste con tinta marino sobre fondos semánticos claros.

## Archivos

Presentación modificada: `lib/theme/mobility_theme.dart`; screens Home/Login/Perfil/Analytics/Validation; widgets app_navigation_drawer, departure_time_selector, historical_departure_guidance_card, map_floating_controls, map_search_panel, mobility_recommendation_summary, navigation_header, navigation_status_card, report_incident_sheet, route_planner_form y travel_mode_selector.

Nuevos componentes de presentación: `mobility_section_card.dart` y `mobility_evidence_summary.dart`. No calculan recomendaciones ni suministran datos demo.

Tests actualizados: analytics (solo presentación/scroll), Perfil, header, fixtures de Home/reportes y assertions de composición. Nuevo `test/visual/visual_fidelity_test.dart`.

## Evidencia y validación

Matriz de 11 composiciones (las nueve vistas más login/navegación) × 320/390/768/1440 × texto 1×/2× = 88 casos. Cuatro casos con teclado 300 px/texto 2× y uno de los cuatro estados de validación: **93 tests visuales/de interacción**. Fixtures y clientes simulados solo en tests; los servicios productivos no se sustituyen.

Galería comparativa: `artifacts/figma-final-fidelity/approved-comparison.html`, fotogramas aprobados frente a capturas `definitive/`. Se generan PNG a 390/1×, 320/2× y 1440/1×. Roboto y Material Icons del SDK local solo se cargan para render de tests. No se agregaron assets de fonts/dependencias al producto.

Comando reproducible (ajustar path de SDK):

```powershell
$env:TI_VISUAL_PHASE = 'definitive'
$env:TI_VISUAL_FONT_ROOT = 'C:\development\flutter\bin\cache\artifacts\material_fonts'
flutter test --no-pub test/visual/visual_fidelity_test.dart
flutter analyze --no-pub
flutter test --no-pub
```

Últimos checks: matriz **93 passed**; regresión específica de Home/reportes **31 passed**; analyze **No issues found!**. `flutter test --no-pub`: **636 passed**, sin fallos. `git diff --check` limpio durante revisión.

No se declara igualdad pixel a pixel: el MP4 es una captura comprimida con escala y marco de simulador; no hay archivo tipográfico ni especificaciones numéricas adicionales. Se usaron los colores exactos solicitados y composición verificable, sin inventar medidas exactas no recuperables.

## Revisión manual en Android

Las capturas son de widgets con datos controlados, mapa sin tiles HTTP reales y sombras/fallback de glyphs del renderer de pruebas. Comparar en dispositivo: safe areas/notch, teclado, TalkBack/foco/texto 200 %, mapa y tiles reales, OAuth/retorno de sesión, permisos GPS, cambios de modo, reportes reales/autorizados/Realtime, routing y navegación vehicular en movimiento. Verificar estados empty/partial/error con backend real.

Diferencias deliberadas: datos reales en vez de muestras, sin controles de demostración, sin transporte público ficticio, sin pronóstico ni tráfico real; metadatos y capacidades conservados. La funcionalidad no se reduce para imitar el demo. No se generó APK ni se publicó el sitio/artefactos.