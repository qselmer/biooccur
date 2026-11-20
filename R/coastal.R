# Extract geometry components explicitly, including nested collections.
# Avoid implicit st_cast dispatch on heterogeneous collection results.
domain_overlay_components <- function(x, type) {
  g <- sf::st_geometry(x)
  allowed <- base::c(type,paste0("MULTI",type))
  parts <- list()
  visit <- function(feature) {
    if (inherits(feature,"GEOMETRYCOLLECTION")) {
      for (item in feature) visit(item)
    } else if (inherits(feature,allowed)) {
      parts[[length(parts)+1L]] <<- feature
    }
    invisible(NULL)
  }
  for (feature in g) visit(feature)
  out <- sf::st_sfc(parts,crs=sf::st_crs(g))
  out[!sf::st_is_empty(out)]
}

domain_polygonal_overlay <- function(x, stage="overlay") {
  p <- domain_overlay_components(x,"POLYGON")
  if (!length(p))
    stop(stage,": no polygonal area; returned types: ",
         paste(unique(as.character(sf::st_geometry_type(x))),collapse=", "))
  p <- p[which(as.numeric(sf::st_area(p)) > 0)]
  if (!length(p)) stop(stage,": no positive-area polygonal components.")
  # Homogeneous geometry avoids unsupported mixed-type coordinate extraction.
  sf::st_cast(p,"MULTIPOLYGON",warn=FALSE)
}

# Preserve original error and expose the exact operation and call stack.
domain_spatial_step <- function(stage, expr) {
  if (isTRUE(getOption("biooccur.spatial.trace",FALSE))) message("Spatial: ",stage)
  withCallingHandlers(force(expr),error=function(e) {
    message("Spatial failure [",stage,"]: ",conditionMessage(e))
    if (isTRUE(getOption("biooccur.spatial.trace",FALSE))) {
      calls <- sys.calls()
      message(paste(vapply(calls,function(z) paste(deparse(z,nlines=2L),collapse=" "),character(1)),collapse="\n"))
    }
  })
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
  clip <- domain_bbox(bbox[1],bbox[2],bbox[3],bbox[4])$geometry
  old <- sf::sf_use_s2()
  on.exit(sf::sf_use_s2(old), add = TRUE)
  sf::sf_use_s2(TRUE)
  # Select whole land features intersecting an expanded search region.
  search <- domain_spatial_step("expanded search buffer",sf::st_buffer(clip, distance_m * 1.1, max_cells = max_cells))
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
  all_land <- domain_spatial_step("regional land selection and union",select_land(land))
  target <- if (is.null(reference_land)) all_land else domain_spatial_step("reference land selection and union",select_land(reference_land))
  # Extract actual shoreline BEFORE clipping to avoid artificial coastlines.
  # Restrict line to expanded search window; no buffer of entire continents.
  shoreline <- domain_spatial_step("shoreline boundary",sf::st_boundary(target))
  regional <- domain_spatial_step("shoreline intersection",sf::st_intersection(shoreline,search))
  lines <- domain_spatial_step("line component extraction",domain_overlay_components(regional,"LINESTRING"))
  if (!length(lines)) stop("No shoreline lines in expanded search window.")
  cells <- max(20000L,max_cells)
  outer <- domain_spatial_step("outer line buffer",sf::st_union(sf::st_buffer(lines, distance_m, max_cells = cells)))
  band <- domain_spatial_step("outer buffer clipping",domain_polygonal_overlay(sf::st_intersection(outer,clip),"Outer buffer clipping"))
  if (min_distance_m > 0) {
    inner <- domain_spatial_step("inner line buffer",sf::st_union(sf::st_buffer(lines,min_distance_m,max_cells=cells)))
    band <- domain_spatial_step("inner distance exclusion",domain_polygonal_overlay(sf::st_difference(band,inner),"Inner distance exclusion"))
  }
  band <- domain_spatial_step("marine land exclusion",domain_polygonal_overlay(sf::st_difference(band,all_land),"Marine land exclusion"))
  message("Marine band: ",paste(as.character(sf::st_geometry_type(band)),collapse=", "))
  result <- domain_spatial_step("final polygon validation",domain_validate(band, repair = TRUE))
  result$reference <- lines
  result$environment <- "marine"
  result$requested_bbox <- bbox
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
