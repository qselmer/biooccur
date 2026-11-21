testthat::test_that("distance partition uses common marine geometry and nautical miles", {
  mainland <- domain_bbox(0,-2,2,2)$geometry
  island <- domain_bbox(-.2,-.1,-.1,.1)$geometry
  land <- sf::st_sf(geometry=base::c(mainland,island))
  ref <- sf::st_sfc(sf::st_linestring(rbind(c(0,-1),c(0,1))),crs="OGC:CRS84")
  d <- domain_distance_partition(land,ref,c(0,10,30),-.5,.5)
  testthat::expect_equal(d$zones[["0-10"]]$distance_m,18520)
  testthat::expect_equal(d$zones[["10-30"]]$min_distance_m,18520)
  testthat::expect_false(domain_contains(d,-.15,0))
  testthat::expect_false(domain_contains(d,-.9,0))
  testthat::expect_true(domain_contains(d,-.3,0))
  testthat::expect_true(domain_band_audit(d,d$zones[[1]],d$zones[[2]])$pass)
})
testthat::test_that("unsupported continental sectors fail explicitly", {
  land <- sf::st_sf(geometry=domain_bbox(0,-2,2,2)$geometry)
  testthat::expect_error(domain_mainland_zones(land,"australia","west",-20,-15,c(0,60)),
    "south_america only")
  testthat::expect_error(domain_mainland_zones(land,"south_america","west",-20,-15,c(0,60,30)),
    "Invalid increasing")
})
