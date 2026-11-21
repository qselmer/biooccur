# Real-data integration checks, using locally cached GSHHG Full.
source("R/main.R")
local({
  run_integration <- function() {
  old <- options(biooccur.spatial.trace=TRUE)
  on.exit(options(old),add=TRUE)
  land <- domain_land()
  cases <- list(
    continental=function() domain_mainland_buffer(land,"south_america","west",-11,-5,60),
    insular=function() domain_island_nmi(land,domain_pick_land(land,-90.35,-.65),30),
    distance_band=function() domain_mainland_buffer(land,"south_america","west",-11,-5,60,20))
  for (name in names(cases)) {
    message("Integration: ",name)
    d <- cases[[name]]()
    stopifnot(all(sf::st_is_valid(d$geometry)),domain_summary(d)$area_km2>0)
    print(domain_summary(d))
  }
  }
  run_integration()
})
