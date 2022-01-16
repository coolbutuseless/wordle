
rm(list = ls())


# letter_freqs  <- strsplit('etaoinshrdlcumwfgypbvkjxqz', '')[[1]]
letter_counts <- table(unlist(strsplit(wordle_dict, '')))
letter_order  <- letters[order(letter_counts, decreasing = TRUE)]



#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Determine if a word has any repeated letters
#'
#' @param words character vector of words
#'
#' @return logical vector
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
has_doubles <- function(words) {
  letters <- strsplit(words, '')

  vapply(letters, function(lets) {
    any(table(lets) > 1)
  }, logical(1))
}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Convert a word to a logical vector of letters it contains
#'
#' @param word single word
#'
#' @return 26-element logical vector. TRUE if the letter in that position is
#'         contained in the word, otherwise FALSE
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
word2vec <- function(word) {
  res <- logical(26)
  res[utf8ToInt(word) - 96] <- TRUE
  res
}



#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# How many words am I searchning for
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
nwords <- 4L

outfile <- sprintf("set-%i.txt", nwords)

if (nwords == 2) {
  top_letters <- paste(letter_order[1:10], collapse = "")
  regex <- sprintf("[%s]{5}", top_letters)
} else if (nwords == 3) {
  top_letters <- paste(letter_order[1:15], collapse = "")
  regex <- sprintf("[%s]{5}", top_letters)
} else if (nwords == 4) {
  top_letters <- paste(letter_order[1:20], collapse = "")
  regex <- sprintf("[%s]{5}", top_letters)
} else {
  regex <- "[a-z]{5}"
}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Build a logical matrix of letter_position x word
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
words  <- sort(unique(wordle::wordle_dict))
length(words)
words <- grep(regex, words, value = TRUE)
length(words)
words <- words[!has_doubles(words)]
length(words)
mat <- sapply(words, word2vec)


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Membership indices
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
has <- list()
hasnot <- list()
for (let in letters) {
  has[[let]] <- which(grepl(let, words))
  hasnot[[let]] <- setdiff(seq_along(words), has[[let]])
}






#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Recursively filter a set of words
#'
#' @param word_idx an index in [1, length(words)]
#' @param remaining_idx all other indexes remaining at this stage
#' @param word_seq integer vector of the word indices up to this point
#' @param letter_vec logical vector of length 26. Set to TRUE if letters
#'        are already present in the word sequence so far
#' @param depth recurstion depth
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
filter_words <- function(word_idx,
                         remaining_idx,
                         word_seq   = c(),
                         letter_vec = rep(F, 26),
                         depth      = 1L) {

  # Bail early if this is uncalculable
  if (length(remaining_idx) == 0L || depth > nwords) return()

  # Filter out any words that intersect with the current word
  word <- words[[word_idx]]
  lets <- strsplit(word, '')[[1L]]
  for (let in lets) {
    remaining_idx <- setdiff(remaining_idx, has[[let]])
  }

  if (length(remaining_idx) == 0L) {
    return()
  }

  # Update the word sequence and the letter vector representation
  word_seq      <- c(word_seq, word_idx)
  letter_vec    <- letter_vec | mat[,word_idx]

  if (depth == nwords - 1L) {
    # terminal condition
    for (j in remaining_idx) {
      cat(words[c(word_seq, j)], "\n")
    }
  } else {
    for (jj in seq_along(remaining_idx)) {
      filter_words(
        word_idx      = remaining_idx[[jj]],
        remaining_idx = remaining_idx[-seq(jj)],
        word_seq      = word_seq,
        letter_vec    = letter_vec,
        depth         = depth + 1L
      )
    }
  }

}


word_idx = 1
remaining_idx = seq_along(words)
word_seq = c()
letter_vec = rep(F, 26)
depth = 1

start <- Sys.time()
all_idx <- seq_along(words)
sink(outfile)
for (i in seq(length(words) - nwords + 1L)) {
  # cat(">> ", i, "\n")
  filter_words(
    word_idx = i,
    remaining_idx = seq.int(i+1L, length(words))
  )
}
sink()
print(Sys.time() - start)


# set 2 = 0.1 seconds
# set 3 = 40 seconds
# set 4 = 1.8 hrs
# set 5 = 8 hours



