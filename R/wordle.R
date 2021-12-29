

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
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
#' @param excluded_letters string containing letters known to not be in the word
#' @param wrong_spot a character vector the same length as the number of letters
#'        in the target word.  Each string in this vector represents all letters
#'        which are known to be part of the word, but in the wrong spot.
#'        E.g. if 'a' has been attempted as the first character, and it exists
#'        in the word, but worlde claims it is not yet in the correct position,
#'        then \code{wrong_spot = c('a', '', '', '', '')}
#' @param known_count name character vector giving letters and their known counts.
#'        E.g. This can be used if it is known definitively that there is only
#'        one letter 'e' in the target word, in which case
#'        \code{known_count = c(e = 1)}
#' @param sort Should the returned words be sorted by score?  Default: TRUE.
#'         The scoring method prioiritises words with common letters like
#'         "e", "t" and "a" over uncommon letters like "q" and "z".
#'         If FALSE, then words will be returned in the same order as given.
#'
#' @return character vector of words filtered from the original words which
#'         match the constraints given.
#'
#' @export
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
filter_words <- function(words,
                         exact = ".....",
                         excluded_letters = "",
                         wrong_spot = c('', '', '', '', ''),
                         known_count = c(),
                         sort = TRUE) {


  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Build a regex to match the exact case, but exclude any words which
  # contain excluded letters, or letters in the wrong spot
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  excluded_letters <- rep(excluded_letters, nchar(exact))

  stopifnot(length(wrong_spot) == nchar(exact))
  excluded_letters <- paste(excluded_letters, wrong_spot, sep = "")
  excluded_letters <- ifelse(nchar(excluded_letters) == 0, '.', paste0("[^", excluded_letters, "]"))

  regex <- strsplit(exact, '')[[1]]
  regex <- ifelse(regex == '.', excluded_letters, regex)
  regex <- paste(regex, collapse = "")
  regex <- paste0('^', regex, '$')


  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Keep only words which match the exact case, and do not contain excluded
  # letters, or letters in the wrong spot
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  words <- grep(regex, words, value = TRUE, ignore.case = TRUE)


  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Built a vector of all included letters regardless of whether they're in
  # the wrong spot or not.
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  included_letters1 <- strsplit(exact, '')[[1]]
  included_letters2 <- unlist(strsplit(wrong_spot, ''))
  included_letters  <- c(included_letters1, included_letters2)
  included_letters  <- included_letters[included_letters != '.']
  included_letters  <- sort(unique(included_letters))

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Check that we have all included letters required
  # Do this by comparing the sorted letters within each word vs a sorted regex
  # e.g. to check for letters 'r' and 'e' in 'rebel'
  #  grepl('e.*r', 'beerl')
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  if (length(included_letters) > 0) {

    sorted_included_letters <- paste(sort(included_letters), collapse = ".*")

    split_words <- strsplit(words, '')
    sorted_letters <- vapply(split_words, function(letters) {
      paste0(sort(letters), collapse = "")
    }, character(1))

    matching_included_letters <- which(grepl(sorted_included_letters, sorted_letters))
    words <- words[matching_included_letters]
  }

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # enforce a known count e.g. if it is known that there is only a single
  # 'e' then drop words like "rebel" from the list of candidate words
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  split_words <- strsplit(words, '')
  for (i in seq_along(known_count)) {
    letter <- names(known_count)[1]
    count  <- known_count[[1]]
    match_counts <- vapply(split_words, function(x) {
      sum(x == letter) == count
    }, logical(1))
    words <- words[match_counts]
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
    #' @field excluded_letters all letters which are known to not be in the
    #'        target word. character vector
    #' @field wrong_spot character vector of strings. Each string contains all
    #'        letters which are known to be part of the word, but do not exist
    #'        at this particular position
    #' @field known_count named vector of known counts for letters e.g. if
    #'        'e' is known only to appear once, then `known_count = c(e = 1)`
    #' @field nchar number of characters in word
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    words = NULL,
    exact = NULL,
    excluded_letters = NULL,
    wrong_spot = NULL,
    known_count = NULL,
    nchar = NULL,

    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    #' Initialize Wordle
    #' @param nchar number of characters in the word
    #' @param word_file source for all words. text file with 1-line-per-word.
    #'        This defaults to \code{/usr/share/dict/words} which should work
    #'        on many macOS and unix-like systems
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    initialize = function(nchar, word_file = "/usr/share/dict/words") {
      self$words <- readLines(word_file)
      self$nchar <- nchar

      self$exact <- rep('.', nchar)
      self$excluded_letters <- c()
      self$wrong_spot <- rep('', nchar)

      self$words <- filter_words(self$words, exact = paste(self$exact, collapse = ""))

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
      stopifnot(nchar(word) == self$nchar)

      #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      # Sanity check that reponse values are one of the three valid
      # colours
      #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      response <- tolower(response)
      response[response == 'gray'] <- 'grey'
      stopifnot(all(response %in% c('green', 'yellow', 'grey')))

      #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
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
      # Letters to be added to the exclusion list are any that are 'grey'
      # but not already in the word, or known to be in the wrong spot
      #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      new_excluded   <- letters[response == 'grey']
      new_excluded   <- setdiff(new_excluded, self$exact)
      all_wrong_spot <- unlist(strsplit(self$wrong_spot, ""))
      new_excluded   <- setdiff(new_excluded, all_wrong_spot)

      #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      # add the new excluded letters to the global list
      #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      self$excluded_letters <- union(self$excluded_letters, new_excluded)


      #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      # If a letter appears in 'word' multiple times, but is sometimes 'grey'
      # then use this to update self$known_count
      #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      tt <- table(letters)
      dupe_letters <- names(tt)[tt > 1]

      for (letter in dupe_letters) {
        # gather all the 'response' for this letter
        # e.g. c('green', 'grey')
        dupe_response <- response[letters == letter]

        # If the response is mixed and includes 'grey', then there must be
        # a limit to the number of times this letter can appear
        if (length(unique(dupe_response) > 1) && any(dupe_response == 'grey')) {
          max_count <- sum(dupe_response != 'grey')
          self$known_count[letter] <- max_count
        }
      }


      #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      # Update the internal wordlist
      #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      self$words <- filter_words(
        words            = self$words,
        exact            = paste(self$exact, collapse = ""),
        excluded_letters = paste(self$excluded_letters, collapse = ""),
        wrong_spot       = self$wrong_spot,
        known_count      = self$known_count
      )

      invisible(NULL)
    }


  )
)


if (FALSE) {
  wordle <- Wordle$new(5)
  wordle$get_suggestions()

  wordle$update(word = "eaten", response = c('yellow', 'yellow', 'grey', 'grey', 'grey'))
  wordle$get_suggestions()

  wordle$update(word = "arise", response = c('green', 'grey', 'green', 'yellow', 'green'))
  wordle$get_suggestions()
}












