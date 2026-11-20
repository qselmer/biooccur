# Spatial configuration ----------------------------------------------------
domain_from_config <- function(config) {
  s <- config$spatial
  if (!is.list(s) || is.null(s$type)) stop("Missing spatial configuration.")
  switch(s$type,
    bbox = do.call(domain_bbox, as.list(s$bbox)),
    polygon = if (!is.null(s$wkt)) domain_import(wkt = s$wkt, crs = s$crs) else
      domain_polygon(do.call(rbind, s$vertices)),
    multipolygon = domain_multipolygon(lapply(s$polygons, function(p) do.call(rbind, p))),
    circle = domain_circle(s$lon, s$lat, s$radius_m),
    exclusion = domain_exclusion(do.call(rbind, s$vertices), lapply(s$holes, function(p) do.call(rbind, p))),
    file = domain_import(path = s$file, crs = s$crs, layer = s$layer),
    region = domain_region(sf::st_read(s$file, quiet = TRUE), s$id_column, unlist(s$ids)),
    coastal_buffer = domain_coastal_buffer(sf::st_read(s$file, quiet = TRUE), s$distance_m,
      if (is.null(s$marine_mask)) NULL else sf::st_read(s$marine_mask, quiet = TRUE)),
    stop("Unknown spatial mode: ", s$type))
}
