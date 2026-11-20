# Environmental masks and spatial diagnostics -------------------------------
# GSHHG L1 separates ocean from land-side area, not freshwater from dry land.
domain_area_m2 <- function(g) {
  if (!length(g) || all(sf::st_is_empty(g))) return(0)
  p <- domain_checked_polygons(g,"Area diagnostic")
  if (!length(p)) return(0)
  sum(as.numeric(sf::st_area(p)))
}

domain_land_mask <- function(domain, land) {
  b <- domain_query_bbox(domain)
  candidates <- domain_land_candidates(land,b)
  if (!length(sf::st_geometry(candidates)))
    return(sf::st_sfc(crs="OGC:CRS84"))
  g <- sf::st_geometry(domain_prepare_land(candidates))
  sf::st_union(g)
}

domain_land_overlap <- function(domain,land) {
  mask <- domain_land_mask(domain,land)
  if (!length(mask)) return(mask)
  domain_checked_polygons(sf::st_intersection(sf::st_union(domain$geometry),mask), "Land overlap")
}

domain_environment <- function(domain, environment="all", land=NULL, custom_mask=NULL) {
  environment <- match.arg(environment,c("all","marine","terrestrial","custom"))
  if (environment=="all") return(domain)
  old <- sf::sf_use_s2()
  on.exit(sf::sf_use_s2(old),add=TRUE)
  sf::sf_use_s2(TRUE)
  g <- sf::st_union(domain$geometry)
  if (environment=="custom") {
    if (is.null(custom_mask)) stop("Custom environment requires a polygon mask.")
    mask <- sf::st_union(domain_validate(custom_mask)$geometry)
    out <- sf::st_intersection(g,mask)
  } else {
    if (is.null(land)) land <- domain_land()
    mask <- domain_land_mask(domain,land)
    # Use the same original land mask for both complementary operations.
    # Avoid subtracting a reconstructed intersection with shared boundaries.
    out <- if (!length(mask)) {
      if(environment=="marine") g else mask
    } else if (environment=="terrestrial") {
      sf::st_intersection(g,mask)
    } else {
      sf::st_difference(g,mask)
    }
  }
  out <- domain_polygonal_overlay(out,paste("Environment",environment))
  result <- domain_validate(out,repair=TRUE)
  result$original <- domain$original
  result$unmasked_geometry <- domain$geometry
  result$environment <- environment
  for (key in c("reference","distance_m","min_distance_m","requested_bbox"))
    result[[key]] <- domain[[key]]
  result
}

domain_metrics <- function(domain,land) {
  old <- sf::sf_use_s2()
  on.exit(sf::sf_use_s2(old),add=TRUE)
  sf::sf_use_s2(TRUE)
  g <- sf::st_union(domain$geometry)
  total <- domain_area_m2(g)/1e6
  terrestrial <- domain_area_m2(domain_land_overlap(domain,land))/1e6
  if (terrestrial > total+max(1e-6,total*1e-8)) stop("Land area exceeds domain area.")
  terrestrial <- min(total,terrestrial)
  marine <- max(0,total-terrestrial)
  parts <- sf::st_cast(g,"POLYGON",warn=FALSE)
  holes <- sum(vapply(parts,function(p) length(p)-1L,integer(1)))
  center <- sf::st_coordinates(sf::st_centroid(g))[1,1:2]
  bbox <- domain_query_bbox(domain)
  data.frame(environment=if(is.null(domain$environment)) "all" else domain$environment,
    features=length(domain$geometry), polygon_components=length(parts), holes=holes,
    area_km2=total, marine_km2=marine, land_side_km2=terrestrial,
    marine_pct=100*marine/total, land_side_pct=100*terrestrial/total,
    perimeter_km=sum(as.numeric(sf::st_length(sf::st_boundary(g))))/1000,
    centroid_lon=center[1],centroid_lat=center[2],
    xmin=unname(bbox[1]),ymin=unname(bbox[2]),xmax=unname(bbox[3]),ymax=unname(bbox[4]),
    requested_min_distance_km=if(is.null(domain$min_distance_m)) NA_real_ else domain$min_distance_m/1000,
    requested_max_distance_km=if(is.null(domain$distance_m)) NA_real_ else domain$distance_m/1000,
    geometry_valid=all(sf::st_is_valid(g)), crs="OGC:CRS84",
    repair_requested=domain$repair_requested, row.names=NULL)
}

# Diagnostic samples: deterministic vertices and regular interior grid.
# Sampled extrema are not continuous-domain guarantees.
domain_buffer_audit <- function(domain,land,n_vertices=1500L,grid_n=35L,
                                distance_tolerance_m=1000,area_tolerance_km2=.01) {
  if(is.null(domain$reference)||is.null(domain$distance_m)||is.null(domain$requested_bbox))
    stop("A shoreline buffer with reference and requested bounds is required.")
  old <- sf::sf_use_s2()
  on.exit(sf::sf_use_s2(old),add=TRUE)
  sf::sf_use_s2(TRUE)
  g <- sf::st_union(domain$geometry)
  xy <- sf::st_coordinates(sf::st_cast(g,"MULTIPOLYGON"))[,1:2,drop=FALSE]
  ids <- unique(round(seq(1,nrow(xy),length.out=min(n_vertices,nrow(xy)))))
  bb <- sf::st_bbox(g)
  grid <- expand.grid(lon=seq(bb[1],bb[3],length.out=grid_n),
                      lat=seq(bb[2],bb[4],length.out=grid_n))
  grid <- grid[domain_contains(domain,grid$lon,grid$lat) %in% TRUE,,drop=FALSE]
  coords <- rbind(unname(xy[ids,,drop=FALSE]),as.matrix(grid))
  pts <- sf::st_as_sf(data.frame(lon=coords[,1],lat=coords[,2]),
    coords=c("lon","lat"),crs="OGC:CRS84")
  d <- as.numeric(sf::st_distance(pts,sf::st_combine(domain$reference)))
  clip <- do.call(domain_bbox,as.list(domain$requested_bbox))$geometry
  outside <- domain_area_m2(domain_overlay_components(sf::st_difference(g,clip),"POLYGON"))/1e6
  on_land <- domain_area_m2(domain_land_overlap(domain,land))/1e6
  lo <- domain$min_distance_m
  hi <- domain$distance_m
  excess <- pmax(lo-d,d-hi,0)
  data.frame(samples=length(d),min_sample_distance_m=min(d),max_sample_distance_m=max(d),
    max_excess_m=max(excess),p95_excess_m=unname(stats::quantile(excess,.95)),
    outside_distance_fraction=mean(excess>distance_tolerance_m),
    land_overlap_km2=on_land,outside_bbox_km2=outside,
    distance_tolerance_m=distance_tolerance_m,area_tolerance_km2=area_tolerance_km2,
    distance_pass=all(excess<=distance_tolerance_m),
    land_pass=on_land<=area_tolerance_km2,bbox_pass=outside<=area_tolerance_km2)
}

domain_band_audit <- function(full,near,far,area_tolerance_km2=.01) {
  old <- sf::sf_use_s2()
  on.exit(sf::sf_use_s2(old),add=TRUE)
  sf::sf_use_s2(TRUE)
  a <- sf::st_union(full$geometry); b <- sf::st_union(near$geometry); c <- sf::st_union(far$geometry)
  combined <- sf::st_union(base::c(b,c))
  overlap <- domain_area_m2(domain_overlay_components(sf::st_intersection(b,c),"POLYGON"))/1e6
  gap <- domain_area_m2(domain_overlay_components(sf::st_difference(a,combined),"POLYGON"))/1e6
  outside <- domain_area_m2(domain_overlay_components(sf::st_difference(combined,a),"POLYGON"))/1e6
  data.frame(overlap_km2=overlap,gap_km2=gap,outside_km2=outside,
    area_tolerance_km2=area_tolerance_km2,pass=max(overlap,gap,outside)<=area_tolerance_km2)
}
