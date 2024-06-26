dir_copy_to <- function(src_dir, 
                        dst_dir, 
                        src_root,
                        dst_root,
                        src_label = "",
                        dst_label = "") {
  check_string(src_dir)
  check_string(dst_dir)

  if (!dir_exists(src_dir)) {
    return()
  }

  src_paths <- dir_ls(src_dir, recurse = TRUE)
  is_dir <- fs::is_dir(src_paths)
  
  dst_paths <- path(dst_dir, path_rel(src_paths, src_dir))

  # First create directories
  dir_create(dst_paths[is_dir])
  # Then copy files
  file_copy_to(
    src_paths = src_paths[!is_dir],
    dst_paths = dst_paths[!is_dir],
    src_root = src_root,
    dst_root = dst_root,
    src_label = src_label,
    dst_label = dst_label
  )
}

file_copy_to <- function(src_paths,
                         dst_paths,
                         src_root,
                         dst_root,
                         src_label = "",
                         dst_label = "") {
  # Ensure all the "to" directories exist
  dst_dirs <- unique(fs::path_dir(dst_paths))
  dir_create(dst_dirs)

  eq <- purrr::map2_lgl(src_paths, dst_paths, file_equal)
  if (any(!eq)) {
    src <- paste0(src_label, path_rel(src_paths[!eq], src_root))
    dst <- paste0(dst_label, path_rel(dst_paths[!eq], dst_root))

    purrr::walk2(src, dst, function(src, dst) {
      cli::cli_inform("Copying {src_path(src)} to {dst_path(dst)}")
    })
  }

  file_copy(src_paths[!eq], dst_paths[!eq], overwrite = TRUE)
}

# Checks init_site() first.
create_subdir <- function(pkg, subdir) {
  if (!fs::dir_exists(pkg$dst_path)) {
    init_site(pkg)
  }
  dir_create(path(pkg$dst_path, subdir))

}

out_of_date <- function(source, target) {
  if (!file_exists(target))
    return(TRUE)

  if (!file_exists(source)) {
    cli::cli_abort(
      "{.fn {source}} does not exist",
      call = caller_env()
    )
  }

  file.info(source)$mtime > file.info(target)$mtime
}

# Path helpers ------------------------------------------------------------

path_abs <- function(path, start = ".") {
  is_abs <- is_absolute_path(path)

  path[is_abs] <- path_norm(path[is_abs])
  path[!is_abs] <- fs::path_abs(path(start, path))

  path_tidy(path)
}

path_first_existing <- function(...) {
  paths <- path(...)
  for (path in paths) {
    if (file_exists(path))
      return(path)
  }

  NULL
}

path_package_pkgdown <- function(path,
                                 package,
                                 bs_version,
                                 error_call = caller_env()) {
  # package will usually be a github package, and check_installed()
  # tries to install from CRAN, which is highly likely to fail.
  if (!is_installed(package)) {
    cli::cli_abort(
      c(
        "Template package {.val {package}} is not installed.",
        i = "Please install before continuing."
      ),
      call = error_call
    )
  }
  base <- system_file("pkgdown", package = package)

  # If bs_version supplied, first try for versioned template
  if (!is.null(bs_version)) {
    ver_path <- path(base, paste0("BS", bs_version), path)
    if (file_exists(ver_path)) {
      return(ver_path)
    }
  }

  path(base, path)
}

path_pkgdown <- function(...) {
  system_file(..., package = "pkgdown")
}

pkgdown_config_relpath <- function(pkg) {
  pkg <- as_pkgdown(pkg)
  config_path <- pkgdown_config_path(pkg$src_path)

  fs::path_rel(config_path, pkg$src_path)
}
