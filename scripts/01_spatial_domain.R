# Run from repository root: Rscript scripts/01_spatial_domain.R config.yml
source("R/main.R")
args <- commandArgs(trailingOnly = TRUE)
config <- yaml::read_yaml(if (length(args)) args[1] else "config.yml")
domain <- domain_from_config(config)
dir.create("cout/spatial", recursive = TRUE, showWarnings = FALSE)
domain_export(domain, "cout/spatial/domain.geojson", overwrite = TRUE)
utils::write.csv(domain_summary(domain), "cout/spatial/domain_summary.csv", row.names = FALSE)
utils::write.csv(as.data.frame(as.list(domain_query_bbox(domain))), "cout/spatial/query_bbox.csv", row.names = FALSE)
land <- domain_land(config$spatial$land_file)
label <- if (is.null(config$spatial$land_file)) "Land: Natural Earth 1:10m" else "Land: supplied reference layer"
p <- domain_plot(domain, land=land, reference=domain$reference, source_label=label,
 subtitle=sprintf("Domain area: %s km²", format(round(domain_summary(domain)$area_km2),big.mark=",")))
ggplot2::ggsave("cout/spatial/F01_study_area.png", p, width=9,height=7,dpi=600,bg="white")
ggplot2::ggsave("cout/spatial/F01_study_area.pdf", p, width=9,height=7,bg="white")
print(domain_summary(domain))
