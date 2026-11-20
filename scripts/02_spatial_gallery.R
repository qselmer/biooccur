source("R/main.R")
# Keep gallery objects local to avoid contaminating the R session.
local({
  # F02: illustrative domains over real geographical reference; not official boundaries.
  message("F02: loading and validating full-resolution shoreline")
  land <- domain_land()
  domain_rectangle <- domain_bbox(-93,-2,-88.5,2)
  domain_irregular <- domain_polygon(rbind(c(-93,-2),c(-91,-2),c(-88.5,-1),c(-89,2.2),c(-92,1)))
  domain_multiple <- domain_multipolygon(list(rbind(c(-92,-1.2),c(-90.8,-1.2),c(-90.8,.2),c(-92,.2)),rbind(c(-90.5,-.9),c(-89.2,-.9),c(-89.2,.4),c(-90.5,.4))))
  message("F02: continental marine buffer")
  domain_continental <- domain_shore_buffer(land,c(-82,-11,-77,-5),111120)
  domain_radial <- domain_circle(-90.3,-.65,100000)
  domain_example_region <- domain_region(sf::st_sf(id="example",geometry=domain_bbox(-93,-2,-89,1.5)$geometry),"id","example")
  domain_with_holes <- domain_exclusion(rbind(c(-93,-2),c(-88.5,-2),c(-88.5,2),c(-93,2)),list(rbind(c(-91.8,-.9),c(-90.6,-.9),c(-90.6,.4),c(-91.8,.4))))
  domain_wkt <- domain_import(wkt="POLYGON ((-93 -2,-89 -2,-90 1.5,-93 -2))",crs=4326)
  message("F02: island selection and buffer")
  island <- domain_pick_land(land,-90.35,-.65)
  domain_insular <- domain_island_buffer(land,island,c(-91.4,-1.5,-89.3,.3),55560)
  message("F02: coastal distance band")
  domain_distance_band <- domain_shore_buffer(land,c(-82,-11,-77,-5),111120,37040)
  domains <- list("A | Bounding box"=domain_rectangle,"B | Irregular polygon"=domain_irregular,"C | Multipolygon"=domain_multiple,
   "D | Coastal buffer: 0–60 nmi"=domain_continental,"E | Center and radius"=domain_radial,"F | Example region"=domain_example_region,
   "G | Internal exclusions"=domain_with_holes,"H | Imported WKT"=domain_wkt,"I | Island buffer: 0–30 nmi"=domain_insular,
   "J | Coastal band: 20–60 nmi"=domain_distance_band)
  message("F02: rendering reference maps")
  plots <- lapply(names(domains),function(n) domain_plot(domains[[n]],n,land=land,
   reference=domains[[n]]$reference,source_label=attr(land,"biooccur_source")))
  fig <- patchwork::wrap_plots(plots,ncol=2)
  fig <- fig + patchwork::plot_annotation(title="F02 | Spatial domain selection",
   subtitle="Illustrative domains using real geographic context")
  dir.create("cout/spatial",recursive=TRUE,showWarnings=FALSE)
  ggplot2::ggsave("cout/spatial/F02_geometry_gallery.png",fig,width=12,height=19,dpi=600,bg="white")
  ggplot2::ggsave("cout/spatial/F02_geometry_gallery.pdf",fig,width=12,height=19,bg="white")
  tab <- do.call(rbind,lapply(names(domains),function(n) cbind(mode=n,domain_summary(domains[[n]]))))
  utils::write.csv(tab,"cout/spatial/F02_geometry_summary.csv",row.names=FALSE)

})
