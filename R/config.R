# Spatial configuration ----------------------------------------------------
domain_from_config <- function(config,land=NULL) {
  s <- config$spatial
  if (!is.list(s) || is.null(s$type)) stop("Missing spatial configuration.")
  marine_modes <- c("shore_buffer","coastal_buffer","coastal_zones","island_buffer")
  if(s$type %in% marine_modes) {
    if(!is.null(s$environment)&&!s$environment %in% c("marine","all"))
      stop("Distance-based marine modes require environment: marine or all.")
    if(is.null(land)) land <- domain_land(s$land_file,if(is.null(s$land_resolution)) "f" else s$land_resolution)
    if(!is.null(s$bbox)||!is.null(s$distance_m)||!is.null(s$min_distance_m))
      stop("Legacy buffer YAML: use latitude limits and nautical-mile distances; island mode uses island selection only.")
    return(switch(s$type,
      shore_buffer=domain_mainland_buffer(land,s$continent,s$coast_side,s$lat_min,s$lat_max,
        s$distance_nmi,reference_file=s$mainland_reference_file),
      coastal_buffer=domain_mainland_buffer(land,s$continent,s$coast_side,s$lat_min,s$lat_max,
        s$max_distance_nmi,s$min_distance_nmi,s$mainland_reference_file),
      coastal_zones=domain_mainland_zones(land,s$continent,s$coast_side,s$lat_min,s$lat_max,
        unlist(s$distance_breaks_nmi),s$mainland_reference_file),
      island_buffer={
        island <- if(!is.null(s$island_file)) sf::st_read(s$island_file,quiet=TRUE) else
          domain_pick_land(land,s$island_lon,s$island_lat)
        domain_island_nmi(land,island,s$max_distance_nmi,
          if(is.null(s$min_distance_nmi)) 0 else s$min_distance_nmi)
      }))
  }
  result <- switch(s$type,
    bbox = do.call(domain_bbox, as.list(s$bbox)),
    polygon = if (!is.null(s$wkt)) domain_import(wkt = s$wkt, crs = s$crs) else
      domain_polygon(do.call(rbind, s$vertices)),
    multipolygon = domain_multipolygon(lapply(s$polygons, function(p) do.call(rbind, p))),
    circle = domain_circle(s$lon, s$lat, s$radius_m),
    exclusion = domain_exclusion(do.call(rbind, s$vertices), lapply(s$holes, function(p) do.call(rbind, p))),
    file = domain_import(path = s$file, crs = s$crs, layer = s$layer),
    region = domain_region(sf::st_read(s$file, quiet = TRUE), s$id_column, unlist(s$ids)),
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
