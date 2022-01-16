
suppressPackageStartupMessages({
  library(dplyr)
  library(magrittr)
  library(readr)
})

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Convert a word into an integer vector showing position of letters in
#' the alphabet.
#'
#' This doesn't deal gracefully with repeated letters. Probably not important
#' at the gross level at which I'm doing this.
#'
#' @param word single word
#'
#' @return 26-element integer vector. With integer 1-5 indicating position
#'         of the letters in a word in the alphabet. Otherwise zero.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
word2pos <- function(word) {
  res <- integer(26)
  res[utf8ToInt(word) - 96] <- seq.int(nchar(word))
  res
}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Create a position matrix
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
words <- sort(unique(wordle::wordle_dict))
system.time({
  pos <- sapply(words, word2pos)
})

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Work out the ranks of letters at each position
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
ranks <- list(
  rank(-apply(pos, 1, \(row) sum(row == 1))),
  rank(-apply(pos, 1, \(row) sum(row == 2))),
  rank(-apply(pos, 1, \(row) sum(row == 3))),
  rank(-apply(pos, 1, \(row) sum(row == 4))),
  rank(-apply(pos, 1, \(row) sum(row == 5)))
)


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Score a word by how well it ranks at each letter position
#'
#' @param word
#' @return score. Lower number means the word is a better match for the
#'         average letter position across all words in the dictionary
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
score_word <- function(word) {
  idx <- utf8ToInt(word) - 96
  ranks[[1]][idx[1]] +
    ranks[[2]][idx[2]] +
    ranks[[3]][idx[3]] +
    ranks[[4]][idx[4]] +
    ranks[[5]][idx[5]]
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Score a bunch of words by soring individually and then totalling
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
score_words <- function(these_words) {
  vapply(these_words, score_word, numeric(1))
}

set <- 2

ortho_sets <- readr::read_fwf(here::here("data-raw", sprintf("set-%i.txt", set)), lazy = FALSE, progress = FALSE)

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Sort within each set
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
ortho_sets <- t(apply(ortho_sets, 1, \(x) x[order(score_words(x))]))
ortho_sets <- as_tibble(as.data.frame(ortho_sets))
ortho_sets <- setNames(ortho_sets, paste0("word", seq(set)))


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Sort sets
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
score     <- apply(ortho_sets, 1, \(x) sum(score_words(x)))
min_score <- apply(ortho_sets, 1, \(x) min(score_words(x)))

ortho_sets$score <- score
ortho_sets$min_score <- min_score


ortho_sets <- ortho_sets %>%
  arrange(score, min_score) %>%
  select(-score, -min_score)


rds_filename <- here::here("data-raw", sprintf("set-%i.rds", set))
saveRDS(ortho_sets, rds_filename)





















