testthat::test_that("environment masks preserve area partition", {
  land <- sf::st_sf(geometry=domain_bbox(0,0,2,2)$geometry)
  d <- domain_bbox(-1,.2,1,1.8)
  m <- domain_environment(d,"marine",land)
  t <- domain_environment(d,"terrestrial",land)
  testthat::expect_equal(domain_contains(m,c(-.5,.5),c(1,1)),c(TRUE,FALSE))
  testthat::expect_equal(domain_contains(t,c(-.5,.5),c(1,1)),c(FALSE,TRUE))
  testthat::expect_equal(domain_summary(m)$area_km2+domain_summary(t)$area_km2,
    domain_summary(d)$area_km2,tolerance=1e-6)
  s <- domain_metrics(d,land)
  testthat::expect_equal(s$marine_pct+s$land_side_pct,100)
  testthat::expect_true(s$geometry_valid)
  testthat::expect_error(domain_environment(d,"custom"),"requires")
})
testthat::test_that("offshore domain has zero land overlap", {
  land <- sf::st_sf(geometry=domain_bbox(0,0,2,2)$geometry)
  d <- domain_bbox(10,10,11,11)
  testthat::expect_equal(domain_metrics(d,land)$marine_pct,100)
  testthat::expect_error(domain_environment(d,"terrestrial",land),"no polygonal area")
})

testthat::test_that("marine and land-side masks are complementary on shared edges", {
  land <- sf::st_sf(geometry=domain_bbox(0,0,2,2)$geometry)
  d <- domain_bbox(-1,.2,1,1.8)
  m <- domain_environment(d,"marine",land)
  t <- domain_environment(d,"terrestrial",land)
  testthat::expect_true(all(sf::st_is_valid(m$geometry)))
  testthat::expect_true(all(sf::st_is_valid(t$geometry)))
  testthat::expect_lt(domain_area_m2(sf::st_intersection(m$geometry,t$geometry))/1e6,.01)
  testthat::expect_lt(domain_area_m2(sf::st_difference(d$geometry,
    sf::st_union(base::c(m$geometry,t$geometry))))/1e6,.01)
})

testthat::test_that("native S2 area overlays distinguish boundary contact from overlap", {
  a <- domain_bbox(0,0,1,1)$geometry
  b <- domain_bbox(1,0,2,1)$geometry
  testthat::expect_equal(domain_s2_area_overlay(a,b,"intersection"),0,tolerance=1e-8)
  testthat::expect_equal(domain_s2_area_overlay(a,a,"difference"),0,tolerance=1e-8)
  testthat::expect_equal(domain_s2_area_overlay(a,a,"intersection"),domain_area_m2(a),tolerance=1e-8)
  land <- sf::st_sf(geometry=b)
  testthat::expect_equal(domain_land_area_m2(domain_validate(a),land),0,tolerance=1e-8)
  testthat::expect_equal(domain_metrics(domain_validate(a),land)$marine_pct,100)
})
testthat::test_that("native S2 band audit preserves exact partition", {
  full <- domain_bbox(0,0,2,2)
  near <- domain_bbox(0,0,1,2)
  far <- domain_validate(domain_polygonal_overlay(sf::st_difference(full$geometry,near$geometry)))
  audit <- domain_band_audit(full,near,far)
  testthat::expect_true(audit$pass)
})

testthat::test_that("buffer audit uses native area diagnostics, not reconstructed overlap", {
  land <- sf::st_sf(geometry=domain_bbox(0,0,2,2)$geometry)
  d <- domain_shore_buffer(land,c(-1,.2,1,1.8),50000)
  fn <- domain_buffer_audit
  isolated <- new.env(parent=environment(fn))
  isolated$domain_land_overlap <- function(...) stop("Obsolete overlap path")
  environment(fn) <- isolated
  out <- fn(d,land,n_vertices=20L,grid_n=5L)
  testthat::expect_true(is.finite(out$land_overlap_km2))
  testthat::expect_equal(out$land_overlap_km2,domain_land_area_m2(d,land)/1e6)
})
