

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
#' Filter a list of words based upon letter constraints
#'
#' @param words character vector of candidate words
#' @param exact single string representing known characters in the word, with
#'        '.' used to indicate the letter at this position is unknown.
#'        E.g. For a 5 letter word if the 3rd and 4th letters are known to be 'a' and 'c', but
#'        all other letters are unknown, then \code{exact = "..ac."}
#' @param wrong_spot a character vector the same length as the number of letters
#'        in the target word.  Each string in this vector represents all letters
#'        which are known to be part of the word, but in the wrong spot.
#'        E.g. if 'a' has been attempted as the first character, and it exists
#'        in the word, but worlde claims it is not yet in the correct position,
#'        then \code{wrong_spot = c('a', '', '', '', '')}
#' @param min_count named character vector giving letters and their minimum counts.
#'        E.g. If it is known that there are at least 2 'o's in the word:
#'        \code{min_count = c(o = 2)}
#' @param known_count named character vector giving letters and their known total counts.
#'        This can be used to exclude all words with a particular letter by setting
#'        the count for that letter to zero.
#' @param sort Should the returned words be sorted by score?  Default: TRUE.
#'         The scoring method prioiritises words with common letters like
#'         "e", "t" and "a" over uncommon letters like "q" and "z".
#'         If FALSE, then words will be returned in the same order as given.
#'
#' @return character vector of words filtered from the original words which
#'         match the constraints given.
#'
#' @import stringi
#' @export
#'
#' @examples
#' \dontrun{
#' # Searching for a word:
#' #
#' # with 9 letters
#' # starting with `p`
#' # containing `v` and `z` somewhere, but not as the first letter
#' # containing only one `z`
#' # without an `a` or an `o` in it
#' #
#' words <- readLines("/usr/share/dict/words")
#'
#' filter_words(
#'   words            = words,
#'   exact            = "p........",
#'   wrong_spot       = c("vz", "", "", "", "", "", "", "", ""),
#'   min_count        = c(v = 1),
#'   known_count      = c(z = 1, a = 0, o = 0)
#' )
#' }
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
filter_words <- function(words,
                         exact = ".....",
                         wrong_spot = c('', '', '', '', ''),
                         min_count = c(),
                         known_count = c(),
                         sort = TRUE) {


  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Build a regex to match the exact case, but exclude any words with
  # letters in the wrong spot
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  wrong_spot_regex <- ifelse(nchar(wrong_spot) == 0, '.', paste0("[^", wrong_spot, "]"))

  regex <- strsplit(exact, '')[[1]]
  regex <- ifelse(regex == '.', wrong_spot_regex, regex)
  regex <- paste(regex, collapse = "")
  regex <- paste0('^', regex, '$')


  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Keep only words which match the exact case, and do not contain excluded
  # letters, or letters in the wrong spot
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  words <- grep(regex, words, value = TRUE, ignore.case = TRUE)


  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # enforce a known minimum count
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  for (i in seq_along(min_count)) {
    letter          <- names(min_count)[i]
    this_min_count  <- min_count[[i]]

    count <- stringi::stri_count_fixed(
      str        = words,
      pattern    = letter,
      opts_fixed = list(case_insensitive = TRUE)
    )

    words <- words[count >= this_min_count]
  }

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # enforce a known exact count
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  for (i in seq_along(known_count)) {
    letter            <- names(known_count)[i]
    this_known_count  <- known_count[[i]]

    count <- stringi::stri_count_fixed(
      str        = words,
      pattern    = letter,
      opts_fixed = list(case_insensitive = TRUE)
    )

    words <- words[count == this_known_count]
  }

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # If requested: Re-order words by their score. lowest first.
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  if (isTRUE(sort)) {
    split_words <- strsplit(words, '')
    word_scores <- vapply(split_words, score_letters, numeric(1))
    words[order(word_scores)]
  } else {
    words
  }
}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' R6 Class for tracking Wordle game state
#'
#' @import R6
#' @export
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Wordle <- R6::R6Class(
  "Worldle",
  public = list(

    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    #' @field words current list of candidated words which match all information
    #'        so far
    #' @field exact string representing which letters are known exactly, with
    #'        a period used to indicate that the letter at this position is
    #'        unknown
    #' @field wrong_spot character vector of strings. Each string contains all
    #'        letters which are known to be part of the word, but do not exist
    #'        at this particular position
    #' @field min_count named vector of known minimum counts
    #' @field known_count named vector of known counts for letters e.g. if
    #'        'e' is known only to appear once, then `known_count = c(e = 1)`
    #' @field nchar number of characters in word
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    words       = NULL,
    exact       = NULL,
    wrong_spot  = NULL,
    min_count   = NULL,
    known_count = NULL,
    nchar       = NULL,

    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    #' Initialize Wordle
    #' @param nchar number of characters in the word
    #' @param words character vector of candidated words
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    initialize = function(nchar, words = wordle_dict) {
      self$words <- words
      self$nchar <- nchar

      self$exact       <- rep('.', nchar)
      self$wrong_spot  <- rep('' , nchar)
      self$min_count   <- c()
      self$known_count <- c()

      self$words <- filter_words(self$words, paste(self$exact, collapse = ""))

      invisible(self)
    },

    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    #' Get some suggestions on candidate words
    #' @param n number of words. default 20. Use `Inf` to get all suggestions.
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    get_suggestions = function(n = 20) {
      head(self$words, n)
    },

    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    #' Update the internal list of candidate words
    #' @param word the attempted word that was entered into the system
    #' @param response a vector of colours representing the response from the
    #'        system to this word. Allowed colours: "green", "yellow", "grey"
    #'        or "gray"
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    update = function(word, response) {


      #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      # Sanity check for length
      #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      stopifnot(length(response) == self$nchar)
      stopifnot(nchar(word)      == self$nchar)

      #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      # Sanity check that reponse values are one of the three valid
      # colours
      #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      response <- tolower(response)
      response[response == 'gray'] <- 'grey'
      stopifnot(all(response %in% c('green', 'yellow', 'grey')))

      #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      # split the word apart as most calculations operate on the
      # individual letters
      #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      letters <- strsplit(word, "")[[1]]

      #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      # If letters are green then update them as being part of the
      # 'exact' set of letters
      #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      self$exact <- ifelse(response == 'green', letters, self$exact)

      #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      # Update 'wrong_spot' with additional letters which are marked yellow
      # at each position.
      #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      self$wrong_spot <- ifelse(response == 'yellow',
                                paste0(self$wrong_spot, letters),
                                self$wrong_spot)


      #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      # Update min_count and known_count
      #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      for (letter in unique(letters)) {

        letter_response <- response[letters == letter]
        if (length(letter_response) == 1L) {
          if (letter_response == 'grey') {
            self$known_count[letter] <- 0
          } else {
            self$min_count[letter] <- max(self$min_count[letter], 1, na.rm = TRUE)
          }
        } else {
          # letter appears more than once
          if (all(letter_response == 'grey')) {
            self$known_count[letter] <- 0
          } else if (all(letter_response %in% c('green', 'yellow'))) {
            self$min_count[letter] <- max(self$min_count[letter], length(letter_response), na.rm = TRUE)
          } else {
            # mix of 'grey' and 'green/yellow', which means that the
            # number that are NOT grey must be the exact known count
            # of that letter in the word
            self$known_count[letter] <- sum(letter_response != 'grey')
          }
        }


      }

      #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      # Update the internal wordlist
      #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      self$words <- filter_words(
        words            = self$words,
        exact            = paste(self$exact, collapse = ""),
        wrong_spot       = self$wrong_spot,
        min_count        = self$min_count,
        known_count      = self$known_count
      )

      invisible(NULL)
    }


  )
)


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Manual test cases
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
if (FALSE) {
  wordle <- Wordle$new(5)
  wordle$get_suggestions()

  wordle$update(word = "eaten", response = c('grey', 'grey', 'yellow', 'grey', 'grey'))
  wordle$get_suggestions()

  wordle$update(word = "torso", response = c('yellow', 'green', 'grey', 'green', 'yellow'))
  wordle$get_suggestions()
}


if (FALSE) {
  words <- readLines("/usr/share/dict/words")

  wordle::filter_words(
    words       = words,
    exact       = ".o.s.",
    wrong_spot  = c("t", "", "", "", "o"),
    min_count   = c(t=1, o=2, s=1),
    known_count = c(r = 0)
  )
}


