% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/test.R
\name{test-dont}
\alias{test-dont}
\title{Test case: don't}
\description{
Test case: don't
}
\examples{
\dontrun{
  abort("This is an error!")
}

# Inline \donttest is silently ommitted
\donttest{message("Hi!")}

# Block \donttest indicated with comments
\donttest{
# This is a comment
1 + 3
}

# And works even when not at the top level
if (TRUE) {
  \donttest{
  1 + 2
  }
}

answer <- 1
\dontshow{
answer <- 42
}
answer # should be 42

# To hide the \dontshow part, for conditional examples
\dontshow{if (FALSE) (if (getRversion() >= "3.4") withAutoprint else force)(\{ # examplesIf}
answer <- 43
\dontshow{\}) # examplesIf}
answer # should be still 42

# But this one runs, and the condition is hidden
\dontshow{if (TRUE) (if (getRversion() >= "3.4") withAutoprint else force)(\{ # examplesIf}
answer <- 43
\dontshow{\}) # examplesIf}
answer
}
\seealso{
Other tests: 
\code{\link{index}},
\code{\link{test-crayon}},
\code{\link{test-figures}},
\code{\link{test-links}},
\code{\link{test-lists}},
\code{\link{test-long-lines}},
\code{\link{test-output-styles}},
\code{\link{test-params}},
\code{\link{test-sexpr-title}},
\code{\link{test-tables}},
\code{\link{test-verbatim}}
}
\concept{tests}
\keyword{internal}
