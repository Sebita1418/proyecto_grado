# Bucaramanga, Girón y Floridablanca: recursos territoriales

La cobertura operativa incluye exclusivamente los tres municipios siguientes.
Los tres archivos proceden de la misma capa Municipio (317), DANE MGN 2024,
con `outFields=*`, `returnGeometry=true`, `outSR=4326`, `f=geojson` y filtro por
DIVIPOLA. La exportación fue realizada por el servidor; los archivos conservan
todos los anillos y posiciones, sin simplificación ni redondeo local.

| Municipio | DIVIPOLA / OBJECTID | Archivo | Geometría | Posiciones | Bytes UTF-8 | Descarga |
| --- | --- | --- | --- | --- | --- | --- |
| Bucaramanga | 68001 / 846 | `bucaramanga-mgn2024.geojson` | Polygon, 1 anillo, sin huecos | 4436 | 181231 | 2026-10-09 |
| Girón | 68307 / 881 | `giron-mgn2024.geojson` | Polygon, 1 anillo, sin huecos | 7696 | 314197 | 2026-10-14 |
| Floridablanca | 68276 / 878 | `floridablanca-mgn2024.geojson` | Polygon, 1 anillo, sin huecos | 3165 | 129423 | 2026-10-14 |

En los tres registros se verificó `mpio_tipo=MUNICIPIO`, `mpio_nano=2024`, el
código concatenado y el nombre exacto (`BUCARAMANGA`, `GIRÓN`, `FLORIDABLANCA`).
Se trata de municipios completos, no de cabeceras urbanas ni del área metropolitana.
Piedecuesta no está incorporada.

SHA-256 de las nuevas descargas:

- Girón: `d21059491f262a3369a10c33da38988a367fa5a9a1bff55d74600146208820a2`.
- Floridablanca: `fa74508977642bd1631f5833f4db38d1624c91845675da880a42e41196e27794`.

Consultas exactas:

- [Girón 68307](https://geoportal.dane.gov.co/mparcgis/rest/services/MGN2024/Serv_CapasMGN_2024/FeatureServer/317/query?where=mpio_cdpmp%3D%2768307%27&outFields=*&returnGeometry=true&outSR=4326&f=geojson).
- [Floridablanca 68276](https://geoportal.dane.gov.co/mparcgis/rest/services/MGN2024/Serv_CapasMGN_2024/FeatureServer/317/query?where=mpio_cdpmp%3D%2768276%27&outFields=*&returnGeometry=true&outSR=4326&f=geojson).

CRS de origen publicado por el servicio: EPSG:3857 (102100); archivos exportados
en WGS84/EPSG:4326, orden longitud-latitud. La licencia CC BY 4.0 y atribución
DANE descritas abajo aplican a los tres recursos. El código comprueba identidad
municipal y vigencia al cargarlos. Los SHA-256 permiten auditar las descargas;
no se sustituyeron límites por nombres, rectángulos o centroides.

## Procedencia del recurso inicial de Bucaramanga

`bucaramanga-mgn2024.geojson` es la respuesta original, sin simplificación ni
redondeo local, de la capa **Municipio (317), Marco Geoestadístico Nacional 2024**,
publicada por el Departamento Administrativo Nacional de Estadística (DANE).

- Entidad: Departamento Administrativo Nacional de Estadística - DANE: www.dane.gov.co.
- Vigencia: 2024 (`mpio_nano=2024`); consulta: 9 de octubre de 2026.
- Identificación: departamento 68, municipio 001, DIVIPOLA 68001, BUCARAMANGA,
  `mpio_tipo=MUNICIPIO`, OBJECTID 846. Corresponde al municipio completo,
  no a la capa Zona Urbana (305), departamento o área metropolitana.
- Geometría: Polygon, un anillo cerrado con 4.436 posiciones, sin huecos.
- CRS del servicio: EPSG:3857 (102100); se solicitó `outSR=4326` y el servidor
  exportó GeoJSON WGS84 en orden **longitud, latitud**. No se interpretaron
  coordenadas proyectadas como grados ni se calculó un límite localmente.
- Tamaño del archivo UTF-8: 181.231 bytes.
- SHA-256: `1dca6635bceacb6ca36b038ecb8906ad1ff3f9e312f6e4bface812562059deb5`.
- No se usaron `maxAllowableOffset`, `geometryPrecision`, cuantización ni
  simplificación. Se conserva el detalle entregado por el servicio.

[Capa y metadatos](https://geoportal.dane.gov.co/mparcgis/rest/services/MGN2024/Serv_CapasMGN_2024/FeatureServer/317).
[Consulta exacta de descarga](https://geoportal.dane.gov.co/mparcgis/rest/services/MGN2024/Serv_CapasMGN_2024/FeatureServer/317/query?where=mpio_cdpmp%3D%2768001%27&outFields=*&returnGeometry=true&outSR=4326&f=geojson).

Licencia: **Creative Commons Attribution 4.0 (CC BY 4.0)**, conforme a la
[política del Geoportal DANE](https://geoportal.dane.gov.co/acerca-del-geoportal/licencia-y-condiciones-de-uso/).
[Texto de la licencia](https://creativecommons.org/licenses/by/4.0/).
La atribución aparece también en el mapa cuando se dibuja el límite. La
exportación de formato/reproyección fue realizada por el servidor del DANE;
el proyecto no modificó los anillos.

El MGN es una referencia geoestadística de una entidad oficial. Se usa como
ámbito operativo de la aplicación y **no certifica un deslinde jurídico** ni
precisión a escala predial. No se afirma que la vigencia 2024 sea la más reciente.

Se investigó además la capa IGAC `ordenamiento/instrumentospot/FeatureServer/1`,
que identifica Bucaramanga con código 68001, pero sus metadatos no especifican
licencia de redistribución. El portal Colombia en Mapas incluye condiciones
restrictivas para la base de fronteras y límites; por eso no se incorporó esa
geometría. El servicio DANE MGN 2025 devolvió el registro municipal con geometría
nula y tampoco se activó. El recurso elegido sí contiene geometría verificable
y permiso explícito de reutilización.
