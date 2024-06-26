% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/build-search-docs.R
\name{build_search}
\alias{build_search}
\title{Build search index}
\usage{
build_search(pkg = ".", override = list())
}
\arguments{
\item{pkg}{Path to package.}

\item{override}{An optional named list used to temporarily override
values in \verb{_pkgdown.yml}}
}
\description{
Build a JSON file encompassing all HTML pages, for use by the search script.
}
\section{YAML config}{
You can exclude some paths from the search index.
Below we exclude the changelog from the search index.

\if{html}{\out{<div class="sourceCode yaml">}}\preformatted{search:
  exclude: ['news/index.html']
}\if{html}{\out{</div>}}
}

\section{Debugging and local testing}{
Locally (as opposed to on GitHub Pages or Netlify for instance),
search won't work if you simply use pkgdown preview of the static files.
You can use \code{servr::httw("docs")} instead.

If search is not working, run \code{pkgdown::pkgdown_sitrep()} to eliminate
common issues such as the absence of URL in the pkgdown configuration file
of your package.
}

