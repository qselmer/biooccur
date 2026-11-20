# BioOccur — Canonical scientific and technical specification

Version: 0.0.2-dev | 2026-11-20

## 1. Mission
Phase I discovers, acquires, harmonizes, validates and characterizes biodiversity occurrence data for marine, freshwater and terrestrial systems. Determine what information exists, where, when, for which taxa, from which sources and with what limitations. Phase II adds environmental and trait data; Phase III adds ecological models. Occurrence density is not abundance; missing records are not confirmed absences.

## 2. Architecture
A single R backend supports CLI/scripts, parameterized Quarto HTML and modular Shiny. English for all code, interfaces, comments, documentation and commits. R/ holds backend functions, modules/ Shiny modules, scripts/ entry points, tests/ validation, docs/ documentation, bib/ references, www/ assets. Local raw/, cin/, cout/ hold original acquisitions, standardized inputs and derived products. Never commit credentials, sensitive records or large datasets. Software license pending; preserve source data licenses.

## 3. Spatial domain
Eight required selection modes: bounding box, irregular polygon, multipolygon, coastal buffer, center/radius, predefined region, polygon with holes, imported GIS file. Accept GeoJSON, zipped Shapefile, GPKG, KML, WKT and vertex CSV. Use Leaflet drawing/editing and sf validation. Explicit CRS, WGS84 interchange, longitude/latitude order, antimeridian and holes. Use appropriate geodesic/projected buffers. Preserve original and normalized geometry. When API geometry support is limited, query a covering region and apply exact local spatial filtering; document boundary inclusion and uncertainty. No silent simplification.

Coastal selection also supports a geographic bounding window, minimum/maximum shoreline distances, marine-only bands and selected island or mainland reference polygons. Cartographic figures show geographic land/ocean context with source attribution; generalized reference coastlines are not certified for precise operational distances.

Default shoreline reference is GSHHG v2.3.7 full resolution (f), level L1, cached locally with provenance. Lower resolutions are explicit choices only; local high-resolution alternatives remain supported. Display cropping must not alter analytical coastline geometry. Preselect regional shoreline candidates before S2 topology validation; validate and repair invalid candidate topology before predicates; retain original source files, report repaired features, and fail explicitly if repair cannot produce valid polygons.

Regional marine buffers use actual shoreline lines extracted before clipping; retain only positive-area polygonal overlay components, fail on empty domains, and document S2 buffer approximation.

## 4. Discovery
Prioritize OBIS and GBIF; iNaturalist and ALA follow connector validation. Extensible adapters with declared capabilities and limits. Preliminary counts include possible duplicates. Four taxonomic modes: unrestricted exploration (default), single taxon, multiple taxa, data-driven selection. Navigate kingdom through species. No mandatory marine filter. Data-driven selection uses configurable counts, independent locations, years and sampling metadata; no universal threshold.

## 5. Acquisition
Dry-run plan, explicit execution, temporal/spatial batches, bounded retries, rate limits, cancellation, resumable manifests and local caching. Record query, geometry hash, retrieval timestamp, source, dataset IDs, checksums, expected/actual counts and job state. Distinguish empty, partial, failed and complete results. Preserve immutable raw responses, DOI/citation and licenses; use GBIF bulk download when appropriate. Never expose credentials.

## 6. Harmonization and validation
Darwin Core mapping preserving original IDs and names, accepted taxonomy, dates and precision, coordinates and uncertainty, depth, occurrence status, eventID, datasetID, basisOfRecord, licenses and provenance. Distinguish missing from zero. Validate coordinates, domain, dates, taxonomy/synonyms, fossils, absence status and source flags. Retain original records and explicit per-rule flags. WoRMS for marine taxonomy where appropriate; document other authorities. Confirm duplicates via reliable identifiers; catalog and spatiotemporal matches are candidates requiring evidence. Preserve cross-source provenance.

## 7. Assessment
Report magnitude, spatial/temporal coverage, taxonomy, event availability, quality and source provenance. Environmental coverage only with covariates. Configurable grids including area-aware options; distinguish unsampled from zero-record cells. Accumulation, rarefaction and completeness require defensible comparable sampling units; otherwise show unavailable with reasons. Record counts are not effort. Fitness-for-use is objective-specific: niche/SDM, alpha/beta/gamma diversity, biogeography, phenology, communities, functional diversity, conservation and climate ecology. Assess evidence and missing prerequisites, not arbitrary universal scores; diversity suitability is assemblage-level.

## 8. Interface
Ten Shiny sections: Project Overview; Spatial Domain; Data Sources; Taxonomic Discovery; Data Acquisition; Taxonomic Validation; Data Quality and Validation; Biodiversity and Data Availability; Multidimensional Data Assessment; Export and Reproducibility. Use bslib, leaflet, DT, plotly as appropriate. Nonblocking acquisitions, persistent configuration, honest empty/error/partial states. Quarto HTML mirrors applicable diagnostics with parameter snapshots, citations and limitations. Shared backend prevents divergent results.

## 9. Mandatory visualization inventory
Stable IDs, associated quantitative tables (or geometry/manifest for F01/F02/F07), documented inputs, units, filters and availability. Interactive views plus publication-quality ggplot2 exports where appropriate: PNG 600 dpi, SVG/PDF. Italic scientific names, accessible palettes, clear labels and no clipping. Never fabricate missing values.

| ID | Figure | Phase |
|---|---|---|
| F01 | Study area map | I |
| F02 | Alternative spatial geometries | I |
| F03 | Record availability by source | I |
| F04 | Taxonomic treemap | I |
| F05 | Taxonomic sunburst | I |
| F06 | Taxonomic record ranking | I |
| F07 | Acquisition progress | I |
| F08 | Taxonomic resolution status | I |
| F09 | Quality-control audit flow | I |
| F10 | Frequency of quality issues | I |
| F11 | Map of valid and flagged records | I |
| F12 | Temporal occurrence series | I |
| F13 | Monthly occurrence distribution | I |
| F14 | Spatial record density | I |
| F15 | Observed richness per cell | I |
| F16 | Sampling-event availability | I |
| F17 | Spatiotemporal Hovmöller | I |
| F18 | Taxonomic-temporal heatmap | I |
| F19 | Source overlap diagram | I |
| F20 | UpSet diagram | I |
| F21 | Species accumulation | I (conditional) |
| F22 | Rarefaction and extrapolation | I (conditional) |
| F23 | Sampling completeness | I (conditional) |
| F24 | Multidimensional availability profile | I |
| F25 | Magnitude versus spatial representativeness | I |
| F26 | Objective-specific fitness-for-use matrix | I |
| F27 | Coordinate uncertainty distribution | I |
| F28 | Depth coverage | I (conditional) |
| F29 | Environmental occurrence space | II–III |
| F30 | Environmental niche coverage and overlap | II–III |

## 10. Exports
Raw, standardized, validated and flagged records; exclusion reasons, provenance, licenses, citations, checksums, geometry, figure tables, plots, YAML, QMD, HTML, logs and software versions. CSV/Parquet, GeoPackage/GeoJSON as appropriate. Honor source licenses and sensitive-record restrictions.

## 11. Testing and releases
testthat unit/integration tests with explicitly synthetic fixtures; opt-in live API tests. Test invalid geometries, holes, multipolygons, antimeridian, empty responses, interrupted/resumed acquisition, duplicate candidates, missing fields and provenance retention. Compare source counts and document discrepancies. Resolve actual dependencies before creating renv lockfile. Roadmap: 0.0.1 foundation; 0.0.2 spatial; 0.0.3 discovery; 0.0.4 acquisition; 0.0.5 validation; 0.0.6 assessment/figures; 0.0.7 Quarto; 0.1.0 integrated Shiny. Software paper requires empirical validation and comparisons with existing tools; novelty is not assumed.

## 12. Status
User reported 12 passing spatial tests and successful F01/F02 generation on the prior revision. Cartographic context, marine distance bands and island selection added; new tests and figures require local execution. No live connectors or Shiny application yet. See [spatial engine documentation](docs/spatial-engine.md).
