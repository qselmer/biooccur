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
    x <- sf::st_geometry(domain_prepare_land(x))
    x <- x[lengths(sf::st_intersects(x, search)) > 0L]
    if (!length(x)) stop("No shoreline reference intersects the search region.")
    sf::st_union(x)
  }
  all_land <- select_land(land)
  target <- if (is.null(reference_land)) all_land else select_land(reference_land)
  # S2 polygon buffer minus land produces a marine distance band.
  outer <- sf::st_buffer(target, distance_m, max_cells = max_cells)
  inner <- if (min_distance_m > 0) sf::st_buffer(target,min_distance_m,max_cells=max_cells) else target
  band <- sf::st_difference(sf::st_intersection(outer,clip), inner)
  band <- sf::st_difference(band, all_land)
  band <- sf::st_collection_extract(band, "POLYGON", warn = FALSE)
  result <- domain_validate(band, repair = TRUE)
  result$reference <- sf::st_boundary(target)
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
  parts <- sf::st_cast(sf::st_geometry(domain_prepare_land(land)), "POLYGON")
  p <- sf::st_sfc(sf::st_point(c(lon,lat)),crs="OGC:CRS84")
  hit <- sf::st_intersects(p,parts,model="closed")[[1]]
  if (length(hit)!=1L) stop("Selection point must identify exactly one land polygon.")
  parts[hit]
}
