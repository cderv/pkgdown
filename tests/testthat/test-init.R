test_that("informative print method", {
  pkg <- local_pkgdown_site(test_path("assets/init-extra-1"))
  expect_snapshot(init_site(pkg))
})

test_that("extra.css and extra.js copied and linked", {
  pkg <- local_pkgdown_site(test_path("assets/init-extra-2"))
  suppressMessages(init_site(pkg))

  expect_true(file_exists(path(pkg$dst_path, "extra.css")))
  expect_true(file_exists(path(pkg$dst_path, "extra.js")))

  skip_if_no_pandoc()
  # Now check they actually get used .
  suppressMessages(build_home(pkg))

  html <- xml2::read_html(path(pkg$dst_path, "index.html"))
  paths <- xpath_attr(html, ".//link", "href")

  expect_true("extra.css" %in% paths)
})

test_that("single extra.css correctly copied", {
  pkg <- local_pkgdown_site(test_path("assets/init-extra-1"))
  suppressMessages(init_site(pkg))

  expect_true(file_exists(path(pkg$dst_path, "extra.css")))
})

test_that("asset subdirectories are copied", {
  pkg <- local_pkgdown_site(test_path("assets/init-asset-subdirs"))
  suppressMessages(init_site(pkg))

  expect_true(file_exists(path(pkg$dst_path, "subdir1", "file1.txt")))
  expect_true(file_exists(path(pkg$dst_path, "subdir1", "subdir2", "file2.txt")))
})

test_that("site meta doesn't break unexpectedly", {
  pkgdown <- as_pkgdown(test_path("assets/reference"))

  # null out components that will vary
  yaml <- site_meta(pkgdown)
  yaml$pkgdown <- "{version}"
  yaml$pkgdown_sha <- "{sha}"
  yaml$pandoc <- "{version}"
  yaml$last_built <- timestamp(as.POSIXct("2020-01-01", tz = "UTC"))

  expect_snapshot(yaml)
})

test_that("site meta includes vignette subdirectories", {
  pkg <- local_pkgdown_site()

  vig_path <- path(pkg$src_path, "vignettes") 
  dir_create(path(vig_path, "a"))
  file_create(path(vig_path, "a", c("a.Rmd", "b.Rmd")))
  pkg <- as_pkgdown(pkg$src_path)

  meta <- site_meta(pkg)
  expect_equal(meta$articles, list("a/a" = "a/a.html", "a/b" = "a/b.html"))
})