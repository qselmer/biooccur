# Cartographic reference ---------------------------------------------------
# GSHHG 2.3.7, full resolution, level 1 (land/ocean).
domain_land <- function(path = NULL, resolution = "f",
                        cache_dir = "raw/reference/gshhg/2.3.7") {
  if (!resolution %in% c("f","h","i","l","c")) stop("Invalid GSHHG resolution.")
  if (is.null(path)) {
    folder <- file.path(cache_dir,resolution)
    stem <- paste0("GSHHS_",resolution,"_L1")
    path <- file.path(folder,paste0(stem,".shp"))
    parts <- file.path(folder,paste0(stem,c(".shp",".shx",".dbf",".prj")))
    if (!all(file.exists(parts) & file.info(parts)$size > 0)) {
      stop("GSHHG reference is missing. Run scripts/00_gshhg_reference.R first.")
    }
    label <- paste0("Land: GSHHG v2.3.7 | ",resolution," | L1")
  } else label <- "Land: supplied reference layer"
  x <- sf::st_read(path, quiet = TRUE)
  if (is.na(sf::st_crs(x))) stop("Land reference must have a known CRS.")
  x <- sf::st_transform(x,"OGC:CRS84")
  attr(x,"biooccur_source") <- label
  x
}

domain_plot <- function(domain, title = "F01 | Study area", land = NULL,
                        reference = NULL, subtitle = NULL, extent = NULL,
                        source_label = NULL) {
  if (is.null(land)) {
    land <- domain_land()
    source_label <- attr(land,"biooccur_source")
  }
  if (is.null(source_label)) source_label <- attr(land,"biooccur_source")
  if (is.null(source_label)) source_label <- "Land: supplied reference layer"
  b <- if (is.null(extent)) domain_query_bbox(domain) else setNames(as.numeric(extent), c("xmin","ymin","xmax","ymax"))
  dx <- max(diff(b[c(1,3)]) * .12, .03)
  dy <- max(diff(b[c(2,4)]) * .12, .03)
  xl <- pmax(-180,pmin(180,b[c(1,3)] + c(-dx,dx)))
  yl <- pmax(-90,pmin(90,b[c(2,4)] + c(-dy,dy)))
  # Crop for display only, never for shoreline calculations.
  old <- sf::sf_use_s2()
  on.exit(sf::sf_use_s2(old), add = TRUE)
  sf::sf_use_s2(FALSE)
  land <- suppressWarnings(sf::st_crop(land, xmin=xl[1], xmax=xl[2], ymin=yl[1], ymax=yl[2]))
  p <- ggplot2::ggplot() +
    ggplot2::geom_sf(data = land, fill = "#E3E2D6", color = "#777E78", linewidth = .23) +
    ggplot2::geom_sf(data = sf::st_sf(geometry = domain$geometry),
      fill = "#28A5C4", alpha = .28, color = NA) +
    ggplot2::geom_sf(data = sf::st_sf(geometry = domain$geometry),
      fill = NA, color = "#075D77", linewidth = .65)
  if (!is.null(reference)) p <- p + ggplot2::geom_sf(data = sf::st_sf(geometry = sf::st_geometry(reference)),
    color = "#A34B25", fill = NA, linewidth = .55)
  p + ggplot2::coord_sf(crs = sf::st_crs("OGC:CRS84"), xlim = xl, ylim = yl, expand = FALSE) +
    ggplot2::labs(title = title, subtitle = subtitle, x = "Longitude", y = "Latitude",
      caption = source_label) +
    ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(panel.background = ggplot2::element_rect(fill = "#E8F3F8", color = NA),
      panel.grid.major = ggplot2::element_line(color = "#BBCED7", linewidth = .25),
      panel.grid.minor = ggplot2::element_blank(),
      panel.border = ggplot2::element_rect(fill = NA, color = "#82969E", linewidth = .35),
      plot.title = ggplot2::element_text(face = "bold", size = 12),
      plot.subtitle = ggplot2::element_text(size = 9),
      plot.caption = ggplot2::element_text(size = 7, color = "#52636C"),
      axis.text = ggplot2::element_text(size = 8),
      axis.title = ggplot2::element_text(size = 9),
      plot.margin = ggplot2::margin(8,10,8,10))
}
