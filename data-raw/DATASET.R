

# Defining as data to avoid some R CRAN package check warnings

blocks <- c(grey = "⬜", yellow = "🟨", green = "🟩")

usethis::use_data(blocks, internal = TRUE, overwrite = TRUE)
