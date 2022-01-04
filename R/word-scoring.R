
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Score each letter by its ranking in letter frequency (in english)
# Score each word by summing the score for each letter
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
letter_freqs  <- strsplit('etaoinshrdlcumwfgypbvkjxqz', '')[[1]]
letter_scores <- setNames(1:26, letter_freqs)
score_letters <- function(letters) sum(letter_scores[letters])

# score_letters(c('h', 'e', 'l', 'l', 'o'))
# score_letters(c('z', 'y', 'x', 'x', 'y'))

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Sort a list of words with words containing the most common english letters coming first
#'
#' @param words character vector
#'
#' @return Sorted, named numeric vector mapping words to letter freq scores
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sort_by_english_letter_freq <- function(words) {
  split_words <- strsplit(words, '')
  word_scores <- vapply(split_words, score_letters, numeric(1))

  res <- setNames(word_scores, words)
  sort(res)
}





#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Convert a word to a logical vector indicating which letters are present
#'
#' @param word string
#' @return logical vector
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
word2vec <- function(word) {
  res <- logical(26)
  res[utf8ToInt(word) - 96] <- TRUE
  res
}



#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Calculate mean number of matching letters between each word and every other word
#'
#' @param words character vector
#' @return named numeric vector. Names = word, values = score
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sort_by_letter_matches <- function(words) {
  mat <- sapply(words, word2vec)
  res <- t(mat) %*% mat
  scores <- colSums(res)
  sort(scores, decreasing = FALSE)
}



#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Convert a word to a integer vector indicating which letters are present
#'
#' @param word string
#' @return integer vector representing the alphabet with letters marked with their
#'         position within the word
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
word2pos <- function(word) {
  res <- integer(26)
  # utf8toInt('a') -> 97
  res[utf8ToInt(word) - 96] <- seq.int(nchar(word))
  res
}



#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Calculate mean match for identical letter positions between each word and every other word
#'
#' @param words character vector
#' @param quiet suppress output? default: FALSE
#'
#' @return named numeric vector. Names = word, values = score
#'
#' @importFrom stats setNames
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sort_by_letter_position_correspondence <- function(words, quiet = FALSE) {

  pos_scores <- sapply(words, word2pos)
  res <- integer(length(words))
  for (i in seq_along(words)) {
    if (i %% 1000 == 0 && !quiet) message(i)
    res[i] <- mean(26 - colSums(pos_scores == pos_scores[,i])[-i])
  }

  res <- setNames(res, words)
  sort(res, decreasing = FALSE)
}
