data_reference_index <- function(pkg = ".", error_call = caller_env()) {
  pkg <- as_pkgdown(pkg)

  meta <- pkg$meta[["reference"]] %||% default_reference_index(pkg)
  if (length(meta) == 0) {
    return(list())
  }

  unwrap_purrr_error(
    rows <- meta %>%
      purrr::imap(data_reference_index_rows, pkg = pkg) %>%
      purrr::compact() %>%
      unlist(recursive = FALSE)
  )

  has_icons <- purrr::some(rows, ~ .x$row_has_icons %||% FALSE)

  check_missing_topics(rows, pkg, error_call = error_call)
  rows <- Filter(function(x) !x$is_internal, rows)

  print_yaml(list(
    pagetitle = tr_("Function reference"),
    rows = rows,
    has_icons = has_icons
  ))
}

data_reference_index_rows <- function(section, index, pkg) {
  is_internal <- identical(section$title, "internal")

  rows <- list()
  if (has_name(section, "title")) {
    rows[[1]] <- list(
      title = markdown_text_inline(section$title),
      slug = make_slug(section$title),
      desc = markdown_text_block(section$desc),
      is_internal = is_internal
    )
  }

  if (has_name(section, "subtitle")) {
    rows[[2]] <- list(
      subtitle = markdown_text_inline(section$subtitle),
      slug = make_slug(section$subtitle),
      desc = markdown_text_block(section$desc),
      is_internal = is_internal
    )
  }


  if (has_name(section, "contents")) {
    id <- section$title %||% section$subtitle %||% index
    check_contents(section$contents, id, pkg)
    topics <- section_topics(section$contents, pkg$topics, pkg$src_path)

    names <- topics$name
    topics$name <- NULL

    rows[[3]] <- list(
      topics = purrr::transpose(topics),
      names = names,
      row_has_icons = !purrr::every(topics$icon, is.null),
      is_internal = is_internal
    )
  }

  purrr::compact(rows)
}

check_contents <- function(contents, id, pkg) {
  malformed <- "This typically indicates that your {pkgdown_config_href(pkg$src_path)} is malformed."
  call <- quote(build_reference_index())

  if (length(contents) == 0) {
    cli::cli_abort(
      c(
        "Section {.val {id}}: {.field contents} is empty.",
        i = malformed
      ),
      call = call
    )
  }

  is_null <- purrr::map_lgl(contents, is.null)
  if (any(is_null)) {
    cli::cli_abort(
      c(
        "Section {.val {id}}: contents {.field {which(is_null)}} is empty.",
        i = malformed
      ),
      call = call
    )
  }

  is_char <- purrr::map_lgl(contents, is.character)
  if (!all(is_char)) {
    cli::cli_abort(
      c(
        "Section {.val {id}}: {.field {which(!is_char)}} must be a character.",
        i = "You might need to add '' around special values like 'N' or 'off'",
        i = malformed
      ), 
      call = call
    )
  }
}

find_icons <- function(x, path) {
  purrr::map(x, find_icon, path = path)
}
find_icon <- function(aliases, path) {
  names <- paste0(aliases, ".png")
  exists <- file_exists(path(path, names))

  if (!any(exists)) {
    NULL
  } else {
    names[which(exists)[1]]
  }
}

default_reference_index <- function(pkg = ".") {
  pkg <- as_pkgdown(pkg)

  exported <- pkg$topics[!pkg$topics$internal, , drop = FALSE]
  if (nrow(exported) == 0) {
    return(list())
  }

  print_yaml(list(
    list(
      title = tr_("All functions"),
      contents = paste0('`', exported$name, '`')
    )
  ))
}

check_missing_topics <- function(rows, pkg, error_call = caller_env()) {
  # Cross-reference complete list of topics vs. topics found in index page
  all_topics <- rows %>% purrr::map("names") %>% unlist(use.names = FALSE)
  in_index <- pkg$topics$name %in% all_topics

  missing <- !in_index & !pkg$topics$internal

  if (any(missing)) {
    cli::cli_abort(c(
      "All topics must be included in reference index",
      "x" = "Missing topics: {pkg$topics$name[missing]}",
      i = "Either add to {pkgdown_config_href({pkg$src_path})} or use @keywords internal"
    ),
    call = error_call)
  }
}
