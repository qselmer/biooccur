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

## GSHHG reference update

The default is now GSHHG 2.3.7 full resolution (f), L1 land/ocean polygons. This supersedes Natural Earth and the prior rnaturalearth dependency. Run Rscript scripts/00_gshhg_reference.R once before F01/F02 or marine buffers. The NOAA archive directory is documented by downstream users but download connectivity and individual file availability have not been verified here. Alternatively obtain the matching shapefile components from the official GSHHG distribution (https://www.soest.hawaii.edu/wessel/gshhg/) and place them under raw/reference/gshhg/2.3.7/f, or supply spatial.land_file. No silent low-resolution fallback. Optional spatial.land_resolution selects f/h/i/l/c; acquire that resolution first. Local data are ignored by Git. Manifest records sizes, MD5 fingerprints and source URLs; these are local fingerprints, not publisher checksum verification. L1 is marine shoreline, not an inland water mask. Full resolution increases processing cost and is not a guarantee of positional accuracy. Display cropping is separate from analytical geometry. New code is unexecuted.

Reference: Wessel & Smith (1996), doi:10.1029/96JB00104.

## Shoreline topology fix

GSHHG full-resolution polygons may fail S2 validation (duplicate vertex). Validate unchecked S2 conversion solely for diagnosis; rebuild invalid features using st_make_valid with 1e7 snap precision, then verify all features before predicates. No resolution downgrade, feature dropping or original-file mutation. Repair may alter local topology and coordinates slightly; report affected feature indices in memory. GEOS display repair/cropping occurs only on a separate copy. The new regression test and real GSHHG gallery require execution. No certification yet.

## Regional topology preparation

User reported 19 passing expectations and three redundant polygon extraction warnings; real GSHHG still failed after global repair. Loading preserves the original global layer without requiring global S2 validity. Display uses local planar geometry only. Coastal and island predicates preselect regional candidates by numeric envelopes before S2 validation. Relevant invalid polygons still fail explicitly if not repairable. Retry invalid features at snap precisions 1e6 and 1e5 after 1e7, accepting only valid polygonal results. Repairs can alter local coordinates at approximately decimeter to meter scale; no certified accuracy. This envelope prefilter is intended for regional shoreline coordinates, not certified for global, polar or antimeridian domains. Conditional extraction removes redundant warnings. Real-data execution pending.
