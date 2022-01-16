
library(dplyr)

set1 <- tibble(word1 = c('soare', 'aeros', 'arose'))
set2 <- readRDS(here::here("data-raw", "set-2.rds"))
set3 <- readRDS(here::here("data-raw", "set-3.rds"))
set4 <- readRDS(here::here("data-raw", "set-4.rds"))
set5 <- readRDS(here::here("data-raw", "set-5.rds"))

orthogonal_words <- list(set1, set2, set3, set4, set5)


usethis::use_data(orthogonal_words, internal = FALSE, overwrite = TRUE, compress = 'xz')
