# Retain only positive-area polygonal components from overlay results.
# Do not silently accept a line-only, point-only or empty domain.
domain_polygonal_overlay <- function(x, stage = "overlay") {
  g <- sf::st_geometry(x)
  types <- as.character(sf::st_geometry_type(g))
  parts <- list()
  for (i in seq_along(g)) {
    if (sf::st_is_empty(g[i])) next
    if (types[i] %in% c("POLYGON","MULTIPOLYGON")) {
      parts[[length(parts)+1L]] <- g[i]
    } else if (types[i] == "GEOMETRYCOLLECTION") {
      p <- sf::st_collection_extract(g[i],"POLYGON",warn=FALSE)
      p <- p[!sf::st_is_empty(p)]
      if (length(p)) parts[[length(parts)+1L]] <- p
    }
  }
  if (!length(parts))
    stop(stage,": no polygonal area; returned types: ",paste(unique(types),collapse=", "))
  p <- base::do.call(base::c, parts)
  p <- p[as.numeric(sf::st_area(p)) > 0]
  if (!length(p)) stop(stage,": no positive-area polygonal components.")
  p
}

# Coastal and island distance domains --------------------------------------
# Buffer the true shoreline before clipping; do not buffer artificial bbox edges.
domain_shore_buffer <- function(land, bbox, distance_m, min_distance_m = 0,
                                reference_land = NULL, max_cells = 5000L) {
  if (length(bbox) != 4L || length(distance_m) != 1L ||
      length(min_distance_m) != 1L ||
      any(!is.finite(c(bbox,distance_m,min_distance_m))) ||
      min_distance_m < 0 || distance_m <= min_distance_m)
    stop("Provide bbox and 0 <= minimum distance < maximum distance in meters.")
  clip <- do.call(domain_bbox, as.list(bbox))$geometry
  old <- sf::sf_use_s2()
  on.exit(sf::sf_use_s2(old), add = TRUE)
  sf::sf_use_s2(TRUE)
  # Select whole land features intersecting an expanded search region.
  search <- sf::st_buffer(clip, distance_m * 1.1, max_cells = max_cells)
  select_land <- function(x) {
    bounds <- s2::s2_bounds_rect(sf::st_as_s2(search))
    xmin <- min(bounds$lng_lo); xmax <- max(bounds$lng_hi)
    if (any(bounds$lng_lo > bounds$lng_hi)) { xmin <- -180; xmax <- 180 }
    candidates <- domain_land_candidates(x,c(xmin,min(bounds$lat_lo),xmax,max(bounds$lat_hi)))
    if (!length(sf::st_geometry(candidates))) stop("No shoreline reference intersects the search region.")
    x <- sf::st_geometry(domain_prepare_land(candidates))
    x <- x[lengths(sf::st_intersects(x, search)) > 0L]
    if (!length(x)) stop("No shoreline reference intersects the search region.")
    sf::st_union(x)
  }
  all_land <- select_land(land)
  target <- if (is.null(reference_land)) all_land else select_land(reference_land)
  # Extract actual shoreline BEFORE clipping to avoid artificial coastlines.
  # Restrict line to expanded search window; no buffer of entire continents.
  shoreline <- sf::st_boundary(target)
  regional <- sf::st_intersection(shoreline, search)
  line_types <- as.character(sf::st_geometry_type(regional))
  lines <- regional[line_types %in% c("LINESTRING","MULTILINESTRING")]
  collections <- regional[line_types == "GEOMETRYCOLLECTION"]
  if (length(collections)) {
    extra <- sf::st_collection_extract(collections,"LINESTRING",warn=FALSE)
    lines <- c(lines,extra)
  }
  lines <- lines[!sf::st_is_empty(lines)]
  if (!length(lines)) stop("No shoreline lines in expanded search window.")
  cells <- max(20000L,max_cells)
  outer <- sf::st_union(sf::st_buffer(lines, distance_m, max_cells = cells))
  band <- domain_polygonal_overlay(sf::st_intersection(outer,clip),"Outer buffer clipping")
  if (min_distance_m > 0) {
    inner <- sf::st_union(sf::st_buffer(lines,min_distance_m,max_cells=cells))
    band <- domain_polygonal_overlay(sf::st_difference(band,inner),"Inner distance exclusion")
  }
  band <- domain_polygonal_overlay(sf::st_difference(band,all_land),"Marine land exclusion")
  message("Marine band: ",paste(as.character(sf::st_geometry_type(band)),collapse=", "))
  result <- domain_validate(band, repair = TRUE)
  result$reference <- lines
  result$distance_m <- distance_m
  result$min_distance_m <- min_distance_m
  result
}

domain_island_buffer <- function(land, island, bbox, distance_m, min_distance_m = 0,
                                 max_cells = 5000L) {
  domain_shore_buffer(land, bbox, distance_m, min_distance_m,
                      reference_land = island, max_cells = max_cells)
}

domain_pick_land <- function(land, lon, lat) {
  if (length(lon)!=1L || length(lat)!=1L || any(!is.finite(c(lon,lat))) ||
      abs(lon)>180 || abs(lat)>90) stop("Invalid land selection point.")
  old <- sf::sf_use_s2()
  on.exit(sf::sf_use_s2(old),add=TRUE)
  sf::sf_use_s2(TRUE)
  candidates <- domain_land_candidates(land,c(lon,lat,lon,lat))
  if (!length(sf::st_geometry(candidates))) stop("Selection point must identify exactly one land polygon.")
  parts <- sf::st_cast(sf::st_geometry(domain_prepare_land(candidates)), "POLYGON")
  p <- sf::st_sfc(sf::st_point(c(lon,lat)),crs="OGC:CRS84")
  hit <- sf::st_intersects(p,parts,model="closed")[[1]]
  if (length(hit)!=1L) stop("Selection point must identify exactly one land polygon.")
  parts[hit]
}
