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
