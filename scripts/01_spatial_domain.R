rm(list = ls()); gc(reset = TRUE)

# Run: Rscript scripts/01_spatial_domain.R config.yml
source("R/main.R")
local({
  args <- commandArgs(trailingOnly=TRUE)
  config <- yaml::read_yaml(if(length(args)) args[1] else "config.yml")
  land <- domain_land(config$spatial$land_file,
    if(is.null(config$spatial$land_resolution)) "f" else config$spatial$land_resolution)
  domain <- domain_from_config(config,land)
  tab <- domain_metrics(domain,land)
  dir.create("cout/spatial",recursive=TRUE,showWarnings=FALSE)
  domain_export(domain,"cout/spatial/domain.geojson",overwrite=TRUE)
  utils::write.csv(tab,"cout/spatial/domain_summary.csv",row.names=FALSE)
  utils::write.csv(as.data.frame(as.list(domain_query_bbox(domain))),"cout/spatial/query_bbox.csv",row.names=FALSE)
  p <- domain_plot(domain,land=land,reference=domain$reference,
    subtitle=sprintf("Total: %s km² | Ocean: %.1f%%",
      format(round(tab$area_km2),big.mark=","),tab$marine_pct))
  ggplot2::ggsave("cout/spatial/F01_study_area.png",p,width=10,height=8,dpi=600,bg="white")
  print(tab)
})
