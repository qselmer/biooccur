# Spatial engine — 0.0.2-dev

Implemented draft backend for eight spatial modes. Install R dependencies:
```r
install.packages(c("sf","s2","yaml","ggplot2","patchwork","testthat"))
```
From repository root:
```powershell
Rscript tests/run-tests.R
Rscript scripts/01_spatial_domain.R config.yml
Rscript scripts/02_spatial_gallery.R
```
Outputs are local in cout/spatial. F01 and F02 have PNG/PDF and associated CSV/geometry. F02 uses synthetic shapes, not actual boundaries.

Configuration examples (spatial section): bbox with bbox: [xmin,ymin,xmax,ymax]; polygon with WKT and CRS or ordered WGS84 vertices; multipolygon with list of vertex lists; circle with lon,lat,radius_m; exclusion with vertices and holes; file with file, optional layer and CRS; region with file,id_column,ids; coastal_buffer with coastline file,distance_m and optional marine_mask file.

Region and coastline layers must be provided by the user; no authoritative boundaries bundled. A coastal buffer is two-sided unless a marine mask is provided. S2 buffers approximate spherical distances; circle uses local azimuthal equidistant projection and a polygon approximation. Geographic edges are geodesic, not constant-latitude lines; rectangular API bounds are conservative covering bounds. Dateline support is intended and covered by an unexecuted test. Large/global domains and ambiguous polygons spanning a hemisphere are not certified. CSV supports one ordered WGS84 exterior ring; use GIS files for multiple rings. ZIP/GDAL driver availability is platform-dependent. Boundary points included; invalid coordinates return NA. Original geometry retained in memory; normalized geometry exported. Repair is opt-in.

No R runtime was available during authoring; tests and figures must be run before certification. Shiny drawing, authoritative region catalog, original geometry persistence and provider-specific WKT serialization remain future work.

## Cartography and marine distance bands (0.0.2-dev refinement)

The user reported 12 passing tests, zero failures/warnings/skips, and successful generation of F01/F02 for the prior revision. A package-build-version warning was reported separately. New tests remain unexecuted.

Install rnaturalearth in addition to prior dependencies. Default land is Natural Earth 1:10m, acquired on demand (internet required); alternatively set spatial.land_file to a local polygon layer. Natural Earth is generalized, suitable for exploratory mapping, not high-precision coastal distance. Use a documented high-resolution local shoreline/land layer for operational work. The maps show ocean, land and study domain. F02 includes ten examples, retaining the original eight and adding island and distance-band examples.

Marine bands use S2 polygon buffers, subtract all supplied land, and intersect a geographic bounding polygon. Distances are approximate spherical buffers; no certified distance accuracy. For mainland-only reference, provide a selected mainland polygon as island_file with type island_buffer, or call domain_shore_buffer with reference_land; otherwise shore_buffer includes all land features. Selection coordinates identify land polygons, not a buffer center. Never use arbitrary nearest-island selection.

Example configuration:
```yaml
spatial:
  type: shore_buffer
  bbox: [-82, -11, -77, -5]
  min_distance_m: 0
  distance_m: 111120
```
```yaml
spatial:
  type: island_buffer
  bbox: [-91.4, -1.5, -89.3, 0.3]
  island_lon: -90.35
  island_lat: -0.65
  distance_m: 55560
```

The latter is an illustrative Santa Cruz selection; if the generalized shoreline does not contain the supplied point, provide an island polygon file instead. Bounds are geographic geodesic polygons, not certified constant-latitude edges. Large/dateline cartography, offline basemap caching and interactive drawing remain pending.
