# Spatial domain engine ----------------------------------------------------
# All public constructors return a biooccur_domain with original and WGS84 geometry.
domain_validate <- function(x, repair = FALSE) {
  if (!inherits(x, c("sf", "sfc"))) stop("Expected an sf or sfc object.")
  if (is.na(sf::st_crs(x))) stop("A known CRS is required.")
  original <- x
  g <- sf::st_transform(sf::st_geometry(x), "OGC:CRS84")
  if (!length(g) || any(sf::st_is_empty(g))) stop("Empty geometry.")
  if (!all(as.character(sf::st_geometry_type(g)) %in% c("POLYGON", "MULTIPOLYGON")))
    stop("Only polygonal domains are supported.")
  # Check coordinates feature-wise: mixed POLYGON/MULTIPOLYGON sfc is valid input.
  valid_xy <- vapply(g,function(feature) {
    xy <- sf::st_coordinates(feature)
    all(is.finite(xy[,1:2])) && all(abs(xy[,1])<=180) && all(abs(xy[,2])<=90)
  },logical(1))
  if (!all(valid_xy)) stop("Invalid geographic coordinates.")
  # Geographic predicates use spherical geometry, including dateline crossings.
  old <- sf::sf_use_s2()
  on.exit(sf::sf_use_s2(old), add = TRUE)
  sf::sf_use_s2(TRUE)
  valid <- sf::st_is_valid(g)
  if (anyNA(valid) || !all(valid)) {
    if (!repair) stop("Invalid geometry; explicitly request repair.")
    g <- sf::st_make_valid(g)
  }
  if (any(sf::st_is_empty(g)) ||
      !all(as.character(sf::st_geometry_type(g)) %in% c("POLYGON", "MULTIPOLYGON")) ||
      !isTRUE(all(sf::st_is_valid(g)))) stop("Invalid polygon after validation.")
  structure(list(original = original, geometry = g, repair_requested = repair),
            class = "biooccur_domain")
}

domain_ring <- function(vertices) {
  v <- as.matrix(vertices)
  if (!is.numeric(v) || ncol(v) != 2L || nrow(v) < 3L ||
      any(!is.finite(v)) || any(abs(v[, 1]) > 180) ||
      any(abs(v[, 2]) > 90)) stop("Provide valid longitude/latitude vertices.")
  if (!all(v[1, ] == v[nrow(v), ])) v <- rbind(v, v[1, ])
  if (nrow(unique(v)) < 3L) stop("At least three distinct vertices required.")
  unname(v)
}

domain_polygon <- function(vertices, holes = list(), repair = FALSE) {
  rings <- c(list(domain_ring(vertices)), lapply(holes, domain_ring))
  domain_validate(sf::st_sfc(sf::st_polygon(rings), crs = "OGC:CRS84"), repair)
}

domain_bbox <- function(xmin, ymin, xmax, ymax) {
  v <- c(xmin, ymin, xmax, ymax)
  if (length(v) != 4L || any(!is.finite(v)) || xmin >= xmax || ymin >= ymax ||
      xmax - xmin >= 180) stop("Use ordered bounds spanning less than 180 degrees; split wider or dateline domains.")
  domain_polygon(rbind(c(xmin,ymin), c(xmax,ymin), c(xmax,ymax), c(xmin,ymax)))
}

domain_multipolygon <- function(polygons, repair = FALSE) {
  if (!is.list(polygons) || !length(polygons)) stop("Provide a list of polygon vertex matrices.")
  parts <- lapply(polygons, function(p) {
    if (is.list(p) && !is.data.frame(p)) {
      c(list(domain_ring(p$vertices)), lapply(p$holes, domain_ring))
    } else list(domain_ring(p))
  })
  domain_validate(sf::st_sfc(sf::st_multipolygon(parts), crs = "OGC:CRS84"), repair)
}

domain_exclusion <- function(vertices, holes, repair = FALSE) {
  if (!length(holes)) stop("At least one exclusion ring is required.")
  domain_polygon(vertices, holes, repair)
}

domain_circle <- function(lon, lat, radius_m, n_quad_segs = 90L) {
  if (length(c(lon, lat, radius_m)) != 3L || any(!is.finite(c(lon, lat, radius_m))) ||
      abs(lon) > 180 || abs(lat) >= 90 || radius_m <= 0 || radius_m > 1000000)
    stop("Provide a valid center and radius in (0, 1000000] meters.")
  p <- sf::st_sfc(sf::st_point(c(lon, lat)), crs = "OGC:CRS84")
  local <- sprintf("+proj=aeqd +lat_0=%s +lon_0=%s +datum=WGS84 +units=m +no_defs", lat, lon)
  g <- sf::st_buffer(sf::st_transform(p, local), radius_m, nQuadSegs = n_quad_segs)
  domain_validate(g)
}

domain_coastal_buffer <- function(coast, distance_m, marine_mask = NULL) {
  if (!inherits(coast, c("sf", "sfc")) || is.na(sf::st_crs(coast)))
    stop("Provide coastline geometry with known CRS.")
  if (!all(as.character(sf::st_geometry_type(coast)) %in% c("LINESTRING", "MULTILINESTRING")))
    stop("Coastline must contain line geometry.")
  if (length(distance_m) != 1L || !is.finite(distance_m) || distance_m <= 0)
    stop("Positive buffer distance in meters required.")
  old <- sf::sf_use_s2()
  on.exit(sf::sf_use_s2(old), add = TRUE)
  sf::sf_use_s2(TRUE)
  g <- sf::st_union(sf::st_buffer(sf::st_transform(sf::st_geometry(coast), "OGC:CRS84"), distance_m))
  if (!is.null(marine_mask)) {
    mask <- domain_validate(marine_mask)$geometry
    g <- sf::st_intersection(g, sf::st_union(mask))
  }
  domain_validate(g)
}

domain_region <- function(regions, id_column, ids) {
  if (!inherits(regions, "sf") || !id_column %in% names(regions) || !length(ids))
    stop("Provide a region layer, identifier column and region IDs.")
  if (!all(ids %in% regions[[id_column]])) stop("Unknown region identifier.")
  domain_validate(regions[regions[[id_column]] %in% ids, , drop = FALSE])
}

domain_import <- function(path = NULL, wkt = NULL, crs = NULL, layer = NULL,
                          repair = FALSE) {
  if (is.null(path) == is.null(wkt)) stop("Specify exactly one of path or WKT.")
  if (!is.null(wkt)) {
    if (is.null(crs)) stop("WKT requires explicit CRS.")
    return(domain_validate(sf::st_as_sfc(wkt, crs = crs), repair))
  }
  if (!file.exists(path)) stop("Spatial file not found.")
  ext <- tolower(tools::file_ext(path))
  if (ext == "csv") {
    if (is.null(crs) || !isTRUE(sf::st_crs(crs) == sf::st_crs("OGC:CRS84")) &&
        !isTRUE(sf::st_crs(crs) == sf::st_crs(4326))) stop("Vertex CSV requires WGS84 CRS.")
    d <- utils::read.csv(path)
    if (!all(c("lon", "lat") %in% names(d))) stop("CSV requires lon and lat columns in ring order.")
    return(domain_polygon(d[, c("lon", "lat")], repair = repair))
  }
  if (ext == "zip") {
    # GDAL virtual filesystem avoids extracting arbitrary archive paths.
    path <- paste0("/vsizip/", normalizePath(path, winslash = "/", mustWork = TRUE))
  }
  x <- if (is.null(layer)) sf::st_read(path, quiet = TRUE) else sf::st_read(path, layer = layer, quiet = TRUE)
  if (is.na(sf::st_crs(x))) {
    if (is.null(crs)) stop("Missing CRS; specify the original CRS explicitly.")
    x <- sf::st_set_crs(x, crs)
  }
  domain_validate(x, repair)
}

domain_contains <- function(domain, lon, lat) {
  if (!inherits(domain, "biooccur_domain") || length(lon) != length(lat) ||
      !is.numeric(lon) || !is.numeric(lat)) stop("Invalid domain or coordinate vectors.")
  out <- rep(NA, length(lon))
  good <- is.finite(lon) & is.finite(lat) & abs(lon) <= 180 & abs(lat) <= 90
  if (!any(good)) return(out)
  p <- sf::st_as_sf(data.frame(lon = lon[good], lat = lat[good]),
                    coords = c("lon", "lat"), crs = "OGC:CRS84")
  old <- sf::sf_use_s2()
  on.exit(sf::sf_use_s2(old), add = TRUE)
  sf::sf_use_s2(TRUE)
  out[good] <- lengths(sf::st_intersects(p, domain$geometry, model = "closed")) > 0L
  out
}

domain_query_bbox <- function(domain) {
  # Conservative geographic covering rectangle, including spherical edge extrema.
  # A global-longitude fallback prevents dateline false negatives.
  r <- s2::s2_bounds_rect(sf::st_as_s2(domain$geometry))
  if (any(r$lng_lo > r$lng_hi) || nrow(r) > 1L)
    return(c(xmin = -180, ymin = min(r$lat_lo), xmax = 180, ymax = max(r$lat_hi)))
  c(xmin = r$lng_lo, ymin = r$lat_lo, xmax = r$lng_hi, ymax = r$lat_hi)
}

domain_summary <- function(domain) {
  old <- sf::sf_use_s2()
  on.exit(sf::sf_use_s2(old), add = TRUE)
  sf::sf_use_s2(TRUE)
  data.frame(features = length(domain$geometry),
             area_km2 = as.numeric(sf::st_area(sf::st_union(domain$geometry))) / 1e6,
             crs = "OGC:CRS84", repair_requested = domain$repair_requested)
}

domain_plot <- function(domain, title = "F01 | Study area") {
  ggplot2::ggplot(sf::st_sf(geometry = domain$geometry)) +
    ggplot2::geom_sf(fill = "#B8DCE5", color = "#176B87", linewidth = 0.5) +
    ggplot2::coord_sf(expand = TRUE) +
    ggplot2::labs(title = title, x = "Longitude", y = "Latitude") +
    ggplot2::theme_minimal(base_size = 16)
}

domain_export <- function(domain, path, overwrite = FALSE) {
  if (file.exists(path) && !overwrite) stop("Output exists.")
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  sf::st_write(sf::st_sf(geometry = domain$geometry), path,
               delete_dsn = overwrite, quiet = TRUE)
  invisible(path)
}
