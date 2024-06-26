test_that("fails if reference index incomplete", {
  pkg <- local_pkgdown_site(test_path("assets/reference"), meta = "
    reference:
     - title: Title
       contents: [a, b, c, e]
  ")
  expect_snapshot(check_pkgdown(pkg), error = TRUE)
})


test_that("fails if article index incomplete", {
  pkg <- local_pkgdown_site(test_path("assets/articles"), meta = "
    articles:
     - title: Title
       contents: [starts_with('html'), random, standard, toc-false, widget, needs-escape]
  ")
  expect_snapshot(check_pkgdown(pkg), error = TRUE)
})

test_that("informs if everything is ok", {
  pkg <- local_pkgdown_site(test_path("assets/reference"))
  expect_snapshot(check_pkgdown(pkg))
})
