# Real-data integration checks, using locally cached GSHHG Full.
source("R/main.R")
local({
  run_integration <- function() {
  old <- options(biooccur.spatial.trace=TRUE)
  on.exit(options(old),add=TRUE)
  land <- domain_land()
  cases <- list(
    continental=function() domain_shore_buffer(land,c(-82,-11,-77,-5),111120),
    insular=function() domain_island_buffer(land,domain_pick_land(land,-90.35,-.65),
        c(-91.4,-1.5,-89.3,.3),55560),
    distance_band=function() domain_shore_buffer(land,c(-82,-11,-77,-5),111120,37040))
  for (name in names(cases)) {
    message("Integration: ",name)
    d <- cases[[name]]()
    stopifnot(all(sf::st_is_valid(d$geometry)),domain_summary(d)$area_km2>0)
    print(domain_summary(d))
  }
  }
  run_integration()
})
