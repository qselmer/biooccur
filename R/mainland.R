# Continental shoreline selection and coastal partitions -------------------
# Built-in sector masks are provisional regional definitions, not ocean boundaries.
# A custom reference must be a mainland-only shoreline supplied by the user.
domain_latitude_strip <- function(xmin,xmax,ymin,ymax) {
  if(xmax-xmin>=180 || xmin>=xmax || ymin>=ymax || ymin<=-90 || ymax>=90)
    stop("Regional latitude strip requires ordered nonpolar bounds spanning <180 longitude degrees.")
  x <- seq(xmin,xmax,length.out=max(2L,ceiling((xmax-xmin)/.05)+1L))
  domain_polygon(rbind(cbind(x,ymin),cbind(rev(x),ymax)))$geometry
}

domain_mainland_reference <- function(land,continent,coast_side,lat_min,lat_max,
                                      margin_deg,reference_file=NULL) {
  if(!coast_side %in% c("west","east","both")) stop("Use coast_side: west, east or both.")
  if(!is.null(reference_file)) {
    x <- sf::st_read(reference_file,quiet=TRUE)
    if(is.na(sf::st_crs(x)) || !all(sf::st_geometry_type(x) %in% c("LINESTRING","MULTILINESTRING")))
      stop("Reference must contain mainland-only shoreline lines with known CRS.")
    lines <- sf::st_geometry(sf::st_transform(x,"OGC:CRS84"))
    if(!length(lines)||any(sf::st_is_empty(lines))||!isTRUE(all(sf::st_is_valid(lines))))
      stop("Invalid custom shoreline.")
    b <- sf::st_bbox(lines)
    if(b[3]-b[1]>=180) stop("Split custom references crossing the dateline or spanning >=180 degrees.")
    strip <- domain_latitude_strip(max(-180,b[1]-.1),min(180,b[3]+.1),
      max(-89.99,lat_min-margin_deg),min(89.99,lat_max+margin_deg))
    return(domain_overlay_components(sf::st_intersection(lines,strip),"LINESTRING"))
  }
  if(!identical(continent,"south_america"))
    stop("Built-in sector currently supports south_america only; provide mainland_reference_file for other continents.")
  # Restrict to a regional latitude range where the inland dividing line
  # separates Pacific and Atlantic shores. No min/max longitude envelope of coast.
  if(lat_min-margin_deg < -53 || lat_max+margin_deg > 7)
    stop("Requested latitude/margin outside provisional South America sector coverage (-53 to 7 degrees). Supply a mainland_reference_file.")
  mainland <- domain_pick_land(land,-60,-15)
  shoreline <- sf::st_boundary(mainland)
  divider <- rbind(c(-72,-53),c(-71,-50),c(-70,-40),c(-65,-30),
                   c(-60,-20),c(-60,-10),c(-65,0),c(-65,7))
  west <- domain_polygon(rbind(c(-96,-53),divider,c(-96,7)))$geometry
  east <- domain_polygon(rbind(divider,c(-30,7),c(-30,-53)))$geometry
  sector <- switch(coast_side,west=west,east=east,both=sf::st_union(base::c(west,east)))
  # Intersect true shoreline, not the boundary of a clipped land polygon.
  lines <- domain_overlay_components(sf::st_intersection(shoreline,sector),"LINESTRING")
  strip <- domain_latitude_strip(-96,-30,lat_min-margin_deg,lat_max+margin_deg)
  domain_overlay_components(sf::st_intersection(lines,strip),"LINESTRING")
}

domain_distance_partition <- function(land,reference,breaks_nmi,lat_min=NULL,lat_max=NULL) {
  old <- sf::sf_use_s2()
  on.exit(sf::sf_use_s2(old),add=TRUE)
  sf::sf_use_s2(TRUE)
  if(!is.numeric(breaks_nmi)||length(breaks_nmi)<2L||any(!is.finite(breaks_nmi))||
      breaks_nmi[1]!=0||any(diff(breaks_nmi)<=0))
    stop("Distance breaks must start at zero and increase strictly.")
  if(!length(reference)) stop("No shoreline in selected sector.")
  max_m <- max(breaks_nmi)*1852
  outer <- sf::st_union(sf::st_buffer(reference,max_m,max_cells=20000L))
  b <- sf::st_bbox(outer)
  if(b[3]-b[1]>=179) stop("Regional extent spans too widely; split the request.")
  # Automatic longitude extent. Latitude strip uses densely sampled parallels.
  xmin <- max(-180,unname(b[1])-.1); xmax <- min(180,unname(b[3])+.1)
  ymin <- if(is.null(lat_min)) max(-89.99,unname(b[2])-.1) else lat_min
  ymax <- if(is.null(lat_max)) min(89.99,unname(b[4])+.1) else lat_max
  clip <- domain_latitude_strip(xmin,xmax,ymin,ymax)
  full <- domain_validate(domain_polygonal_overlay(sf::st_intersection(outer,clip),"Latitude clipping"),repair=TRUE)
  mask <- domain_land_mask(full,land)
  g <- sf::st_union(full$geometry)
  if(length(mask)) g <- sf::st_difference(g,mask)
  full <- domain_validate(domain_polygonal_overlay(g,"Marine exclusion"),repair=TRUE)
  base_geo <- sf::st_union(full$geometry)
  make_domain <- function(g,lo,hi) {
    d <- domain_validate(domain_polygonal_overlay(g,"Distance partition"),repair=TRUE)
    d$environment <- "marine"; d$reference <- reference
    d$min_distance_m <- lo*1852; d$distance_m <- hi*1852
    d$requested_clip <- clip
    d$requested_bbox <- c(xmin,ymin,xmax,ymax)
    d$lat_min <- ymin; d$lat_max <- ymax
    d
  }
  # Partition one common marine domain. Each successive zone is taken from
  # the still-unassigned remainder, preventing independent buffer gaps.
  remaining <- base_geo
  zones <- vector("list",length(breaks_nmi)-1L)
  for(i in seq_along(zones)) {
    lo <- breaks_nmi[i]; hi <- breaks_nmi[i+1L]
    if(i==length(zones)) {
      z <- remaining
    } else {
      inner <- sf::st_union(sf::st_buffer(reference,hi*1852,max_cells=20000L))
      z <- sf::st_intersection(remaining,inner)
    }
    zones[[i]] <- make_domain(z,lo,hi)
    if(i<length(zones)) remaining <- sf::st_difference(remaining,sf::st_union(zones[[i]]$geometry))
  }
  names(zones) <- paste(head(breaks_nmi,-1),tail(breaks_nmi,-1),sep="-")
  out <- make_domain(base_geo,0,max(breaks_nmi))
  out$zones <- zones
  out
}

domain_mainland_zones <- function(land,continent,coast_side,lat_min,lat_max,
                                  distance_breaks_nmi,reference_file=NULL) {
  if(length(lat_min)!=1L||length(lat_max)!=1L||any(!is.finite(c(lat_min,lat_max)))||
     lat_min>=lat_max||lat_min<=-90||lat_max>=90) stop("Invalid latitude limits.")
  if(!is.numeric(distance_breaks_nmi)||length(distance_breaks_nmi)<2L||
      any(!is.finite(distance_breaks_nmi))||distance_breaks_nmi[1]!=0||
      any(diff(distance_breaks_nmi)<=0)) stop("Invalid increasing distance breaks starting at zero.")
  old <- sf::sf_use_s2()
  on.exit(sf::sf_use_s2(old),add=TRUE)
  sf::sf_use_s2(TRUE)
  margin <- max(distance_breaks_nmi)*1852/110000*1.15+.1
  lines <- domain_mainland_reference(land,continent,coast_side,lat_min,lat_max,margin,reference_file)
  d <- domain_distance_partition(land,lines,distance_breaks_nmi,lat_min,lat_max)
  d$continent <- continent; d$coast_side <- coast_side
  d$zones <- lapply(d$zones,function(z) {z$continent <- continent; z$coast_side <- coast_side; z})
  d
}

domain_mainland_buffer <- function(land,continent,coast_side,lat_min,lat_max,
                                   max_distance_nmi,min_distance_nmi=0,reference_file=NULL) {
  if(length(min_distance_nmi)!=1L||length(max_distance_nmi)!=1L||
    any(!is.finite(c(min_distance_nmi,max_distance_nmi)))||
    min_distance_nmi<0||max_distance_nmi<=min_distance_nmi) stop("Invalid distance interval in nmi.")
  breaks <- unique(c(0,min_distance_nmi,max_distance_nmi))
  d <- domain_mainland_zones(land,continent,coast_side,lat_min,lat_max,breaks,reference_file)
  d$zones[[length(d$zones)]]
}

domain_island_nmi <- function(land,island,max_distance_nmi,min_distance_nmi=0) {
  if(length(min_distance_nmi)!=1L||length(max_distance_nmi)!=1L||
     any(!is.finite(c(min_distance_nmi,max_distance_nmi)))||min_distance_nmi<0||
     max_distance_nmi<=min_distance_nmi) stop("Invalid island distance interval in nmi.")
  old <- sf::sf_use_s2()
  on.exit(sf::sf_use_s2(old),add=TRUE)
  sf::sf_use_s2(TRUE)
  g <- sf::st_union(domain_validate(island)$geometry)
  ref <- sf::st_boundary(g)
  d <- domain_distance_partition(land,ref,unique(c(0,min_distance_nmi,max_distance_nmi)))
  d$zones[[length(d$zones)]]
}
