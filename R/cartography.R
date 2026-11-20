# Cartographic reference ---------------------------------------------------
# Natural Earth 1:10m land polygons; display and exploratory shoreline only.
domain_land <- function(path = NULL) {
  x <- if (is.null(path)) rnaturalearth::ne_download(scale = 10, type = "land",
    category = "physical", returnclass = "sf") else sf::st_read(path, quiet = TRUE)
  sf::st_transform(x, "OGC:CRS84")
}

domain_plot <- function(domain, title = "F01 | Study area", land = NULL,
                        reference = NULL, subtitle = NULL, extent = NULL,
                        source_label = NULL) {
  if (is.null(land)) {
    land <- domain_land()
    source_label <- "Land: Natural Earth 1:10m"
  }
  if (is.null(source_label)) source_label <- "Land: supplied reference layer"
  b <- if (is.null(extent)) domain_query_bbox(domain) else setNames(as.numeric(extent), c("xmin","ymin","xmax","ymax"))
  dx <- max(diff(b[c(1,3)]) * .12, .03)
  dy <- max(diff(b[c(2,4)]) * .12, .03)
  xl <- pmax(-180,pmin(180,b[c(1,3)] + c(-dx,dx)))
  yl <- pmax(-90,pmin(90,b[c(2,4)] + c(-dy,dy)))
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
