#' Initialise site infrastructure
#'
#' @description
#' `init_site()`:
#'
#' * creates the output directory (`docs/`),
#' * generates a machine readable description of the site, used for autolinking,
#' * copies CSS/JS assets and extra files, and
#' * runs `build_favicons()`, if needed.
#'
#' See `vignette("customise")` for the various ways you can customise the
#' display of your site.
#'
#' # Build-ignored files
#' We recommend using [usethis::use_pkgdown()] to build-ignore `docs/` and
#' `_pkgdown.yml`. If use another directory, or create the site manually,
#' you'll need to add them to `.Rbuildignore` yourself. A `NOTE` about
#' an unexpected file during `R CMD CHECK` is an indication you have not
#' correctly ignored these files.
#'
#' @inheritParams build_articles
#' @export
init_site <- function(pkg = ".") {
  pkg <- as_pkgdown(pkg)

  if (is_non_pkgdown_site(pkg$dst_path)) {
    cli::cli_abort(c(
      "{.file {pkg$dst_path}} is non-empty and not built by pkgdown",
      "!" = "Make sure it contains no important information \\
             and use {.run pkgdown::clean_site()} to delete its contents."
      )
    )
  }

  cli::cli_rule("Initialising site")
  dir_create(pkg$dst_path)

  copy_assets(pkg)
  if (pkg$bs_version > 3) {
    build_bslib(pkg)
  }

  if (has_logo(pkg) && !has_favicons(pkg)) {
    # Building favicons is expensive, so we hopefully only do it once.
    build_favicons(pkg)
  }
  copy_favicons(pkg)
  copy_logo(pkg)

  build_site_meta(pkg)

  invisible()
}

copy_assets <- function(pkg = ".") {
  pkg <- as_pkgdown(pkg)
  template <- purrr::pluck(pkg$meta, "template", .default = list())

  # pkgdown assets
  if (!identical(template$default_assets, FALSE)) {
    copy_asset_dir(
      pkg, 
      path_pkgdown(paste0("BS", pkg$bs_version, "/", "assets")), 
      src_root = path_pkgdown(),
      src_label = "<pkgdown>/"
    )
  }

  # package assets
  if (!is.null(template$package)) {
    copy_asset_dir(
      pkg, 
      path_package_pkgdown("assets", template$package, pkg$bs_version),
      src_root = system_file(package = template$package),
      src_label = paste0("<", template$package, ">/")
    )
  }

  # extras
  copy_asset_dir(pkg, "pkgdown", file_regexp = "^extra")
  # site assets
  copy_asset_dir(pkg, "pkgdown/assets")

  invisible()
}

copy_asset_dir <- function(pkg,
                           dir,
                           src_root = pkg$src_path,
                           src_label = "",
                           file_regexp = NULL) {
  src_dir <- path_abs(dir, pkg$src_path)
  if (!file_exists(src_dir)) {
    return(character())
  }

  src_paths <- dir_ls(src_dir, recurse = TRUE)
  src_paths <- src_paths[!fs::is_dir(src_paths)]
  if (!is.null(file_regexp)) {
    src_paths <- src_paths[grepl(file_regexp, path_file(src_paths))]
  }
  src_paths <- src_paths[path_ext(src_paths) != "scss"] # Handled in bs_theme()

  dst_paths <- path(pkg$dst_path, path_rel(src_paths, src_dir))

  file_copy_to(
    src_paths = src_paths,
    src_root = src_root,
    src_label = src_label,
    dst_paths = dst_paths,
    dst_root = pkg$dst_path
  )
}

timestamp <- function(time = Sys.time()) {
  attr(time, "tzone") <- "UTC"
  strftime(time, "%Y-%m-%dT%H:%MZ", tz = "UTC")
}

# Generate site meta data file (available to website viewers)
build_site_meta <- function(pkg = ".") {
  meta <- site_meta(pkg)

  # Install pkgdown.yml to ./inst if requested,
  install_metadata <- pkg$install_metadata %||% FALSE
  if (install_metadata) {
    path_meta <- path(pkg$src_path, "inst", "pkgdown.yml")

    dir_create(path_dir(path_meta))
    write_yaml(meta, path_meta)
  }

  path_meta <- path(pkg$dst_path, "pkgdown.yml")
  write_yaml(meta, path_meta)
  invisible()
}

site_meta <- function(pkg) {
  article_index <- article_index(pkg)

  meta <- list(
    pandoc = as.character(rmarkdown::pandoc_version()),
    pkgdown = as.character(utils::packageDescription("pkgdown", fields = "Version")),
    pkgdown_sha = utils::packageDescription("pkgdown")$GithubSHA1,
    articles = as.list(article_index),
    last_built = timestamp()
  )

  if (!is.null(pkg$meta$url)) {
    meta$urls <- list(
      reference = paste0(pkg$meta$url, "/reference"),
      article = paste0(pkg$meta$url, "/articles")
    )
  }

  print_yaml(meta)
}

is_non_pkgdown_site <- function(dst_path) {
  if (!dir_exists(dst_path)) {
    return(FALSE)
  }

  top_level <- dir_ls(dst_path)
  top_level <- top_level[!path_file(top_level) %in% c("CNAME", "dev", "deps")]

  length(top_level) >= 1 && !"pkgdown.yml" %in% path_file(top_level)
}
