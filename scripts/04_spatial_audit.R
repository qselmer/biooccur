# Quantitative checks using real GSHHG; report diagnostics, not automatic certification.
source("R/main.R")
local({
  land <- domain_land()
  full <- domain_mainland_zones(land,"south_america","west",-11,-5,c(0,20,60))
  near <- full$zones[["0-20"]]
  far <- full$zones[["20-60"]]
  island <- domain_island_nmi(land,domain_pick_land(land,-90.35,-.65),30)
  cases <- list(continental=full,near_coast=near,distance_band=far,insular=island)
  tab <- base::do.call(base::rbind,lapply(names(cases),function(n) {
    message("Spatial audit: ",n)
    cbind(case=n,domain_buffer_audit(cases[[n]],land))
  }))
  message("Spatial audit: band closure")
  bands <- domain_band_audit(full,near,far)
  dir.create("cout/spatial",recursive=TRUE,showWarnings=FALSE)
  utils::write.csv(tab,"cout/spatial/spatial_distance_audit.csv",row.names=FALSE)
  utils::write.csv(bands,"cout/spatial/spatial_band_audit.csv",row.names=FALSE)
  print(tab)
  print(bands)
  if(!all(tab$distance_pass & tab$land_pass & tab$bbox_pass) || !bands$pass)
    message("Spatial tolerances not met. Review audit before certification.")
})
