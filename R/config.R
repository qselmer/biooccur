# Spatial configuration ----------------------------------------------------
domain_from_config <- function(config,land=NULL) {
  s <- config$spatial
  if (!is.list(s) || is.null(s$type)) stop("Missing spatial configuration.")
  result <- switch(s$type,
    bbox = do.call(domain_bbox, as.list(s$bbox)),
    polygon = if (!is.null(s$wkt)) domain_import(wkt = s$wkt, crs = s$crs) else
      domain_polygon(do.call(rbind, s$vertices)),
    multipolygon = domain_multipolygon(lapply(s$polygons, function(p) do.call(rbind, p))),
    circle = domain_circle(s$lon, s$lat, s$radius_m),
    exclusion = domain_exclusion(do.call(rbind, s$vertices), lapply(s$holes, function(p) do.call(rbind, p))),
    file = domain_import(path = s$file, crs = s$crs, layer = s$layer),
    region = domain_region(sf::st_read(s$file, quiet = TRUE), s$id_column, unlist(s$ids)),
    shore_buffer = domain_shore_buffer(if(is.null(land)) domain_land(s$land_file, if (is.null(s$land_resolution)) "f" else s$land_resolution) else land, unlist(s$bbox),
      s$distance_m, if (is.null(s$min_distance_m)) 0 else s$min_distance_m),
    island_buffer = {
      if(is.null(land)) land <- domain_land(s$land_file, if (is.null(s$land_resolution)) "f" else s$land_resolution)
      island <- if (!is.null(s$island_file)) sf::st_read(s$island_file,quiet=TRUE) else
        domain_pick_land(land,s$island_lon,s$island_lat)
      domain_island_buffer(land,island,unlist(s$bbox),s$distance_m,
        if (is.null(s$min_distance_m)) 0 else s$min_distance_m)
    },
    coastal_buffer = domain_coastal_buffer(sf::st_read(s$file, quiet = TRUE), s$distance_m,
      if (is.null(s$marine_mask)) NULL else sf::st_read(s$marine_mask, quiet = TRUE)),
    stop("Unknown spatial mode: ", s$type))
  environment <- if(is.null(s$environment)) "all" else s$environment
  if(environment %in% c("marine","terrestrial") && is.null(land))
    land <- domain_land(s$land_file,if(is.null(s$land_resolution)) "f" else s$land_resolution)
  custom <- if(identical(environment,"custom")) {
    if(is.null(s$environment_mask)) stop("Custom environment requires spatial.environment_mask.")
    sf::st_read(s$environment_mask,quiet=TRUE)
  } else NULL
  domain_environment(result,environment,land,custom)
}
