testthat::test_that("marine bands exclude land and respect geographic clipping", {
  land <- sf::st_sf(geometry=domain_bbox(0,0,2,2)$geometry)
  d <- domain_shore_buffer(land,c(-1,.2,1,1.8),50000)
  testthat::expect_equal(domain_contains(d,c(-.1,.1,-.9,-.1),c(1,1,1,1.9)),c(TRUE,FALSE,FALSE,FALSE))
  band <- domain_shore_buffer(land,c(-1,.2,1,1.8),50000,20000)
  testthat::expect_equal(domain_contains(band,c(-.05,-.3),c(1,1)),c(FALSE,TRUE))
  island <- domain_pick_land(land,1,1)
  testthat::expect_true(domain_contains(domain_island_buffer(land,island,c(-1,.2,1,1.8),50000),-.1,1))
  testthat::expect_error(domain_pick_land(land,-1,1))
})

testthat::test_that("shoreline topology is checked before S2 predicates", {
  # Synthetic self-touching ring with a nonconsecutive repeated vertex.
  ring <- rbind(c(0,0),c(2,0),c(2,2),c(1,1),c(0,2),c(1,1),c(0,0))
  g <- sf::st_sfc(sf::st_polygon(list(ring)),crs="OGC:CRS84")
  fixed <- domain_prepare_land(sf::st_sf(id=1L,geometry=g))
  testthat::expect_true(all(s2::s2_is_valid(sf::st_as_s2(sf::st_geometry(fixed),check=FALSE))))
  testthat::expect_equal(fixed$id,1L)
  testthat::expect_equal(attr(fixed,"biooccur_repaired_features"),1L)
})

testthat::test_that("unrelated invalid land does not block regional predicates", {
  local <- domain_bbox(0,0,2,2)$geometry
  ring <- rbind(c(30,30),c(32,30),c(32,32),c(31,31),c(30,32),c(31,31),c(30,30))
  remote <- sf::st_sfc(sf::st_polygon(list(ring)),crs="OGC:CRS84")
  land <- sf::st_sf(geometry=c(local,remote))
  testthat::expect_equal(length(sf::st_geometry(domain_land_candidates(land,c(-1,-1,3,3)))),1L)
  testthat::expect_warning(d <- domain_shore_buffer(land,c(-1,.2,1,1.8),50000), NA)
  testthat::expect_true(domain_contains(d,-.1,1))
  testthat::expect_equal(length(domain_pick_land(land,1,1)),1L)
})
