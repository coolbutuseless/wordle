


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ANSI code setup
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
cols <- c(
  "\033[48;5;249m", # grey
  "\033[48;5;226m", # yellow
  "\033[48;5;46m"   # green
)

black_text <- "\033[38;5;232m"
reset      <- "\033[39m\033[49m"




#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Wordle Game Engine
#'
#' @export
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
WordleGame <- R6::R6Class(
  "WordleGame",

  public = list(

    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    #' @field words character vector of words
    #' @field target_word target word chosen random during initialisation
    #' @field target character vector of letters in target word
    #' @field attempts vector of attempted words
    #' @field responses list of responses for each attempte
    #' @field nchar number of characters in all words
    #' @field dark_mode logical.
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    words       = NULL,
    target_word = NULL,
    target      = NULL,
    attempts    = NULL,
    responses   = NULL,
    nchar       = NULL,
    dark_mode   = NULL,

    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    #' Initialise a WordleGame object
    #'
    #' @param words character vector of candidate words
    #' @param dark_mode if using darkmode, set to TRUE
    #' @param debug logical. default FALSE
    #' @param target_word specify the target word instead of choosing randomly.
    #'        Useful for debugging.
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    initialize = function(words, dark_mode = TRUE, debug = FALSE, target_word = NULL) {
      stopifnot(length(unique(nchar(words))) == 1)
      self$nchar <- nchar(words[1])
      self$words <- tolower(words)

      self$attempts <- c()
      self$responses <- list()

      if (is.null(target_word)) {
        self$target_word <- sample(words, 1)
      } else {
        stopifnot(target_word %in% self$words)
        self$target_word <- target_word
      }
      self$target <- strsplit(self$target_word, '')[[1]]

      if (debug) {
        message(self$target_word)
      }

      self$dark_mode <- isTRUE(dark_mode)

      invisible(self)
    },

    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    #' Play a word and see what the response is
    #'
    #' @param word string
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    try = function(word) {
      if (nchar(word) != self$nchar) {
        message("Word must have ", self$nchar, " letters")
        return(invisible(NULL))
      }

      if (!word %in% self$words) {
        message("Not a valid word in the word list.")
        return(invisible(NULL))
      }

      if (self$target_word %in% self$attempts) {
        message("You've already solved this!")
        return(invisible(NULL))
      }
      self$attempts <- c(self$attempts, word)


      guess <- strsplit(word, '')[[1]]

      exact   <- 2L * (self$target == guess)
      inexact <- which(self$target != guess)

      for (i in inexact) {
        for (j in inexact) {
          wrong_spot = guess[i] == self$target[j]
          if (wrong_spot) {
            exact[i] <- 1L
            inexact <- inexact[inexact != j]
          }
        }
      }


      if (self$dark_mode)
        cat(black_text)

      cat(paste0(cols[exact+1], ' ', guess))
      cat("", reset, "\n")

      response <- c('grey', 'yellow', 'green')[exact + 1]

      self$responses <- append(self$responses, list(response))

      response
    },

    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    #' @description is the game solved?
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    is_solved = function() {
      self$target_word %in% self$attempts
    },

    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    #' @description Print a shareable text block showing the attempts
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    share = function() {

      for (response in self$responses) {
        cat(blocks[response], sep = "")
        cat("\n")
      }
      invisible(self)
    }

  )
)



#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Play Wordle in the R console
#' This is a very naive implementation.
#'
#' @param words character vector of candidate words
#' @param dark_mode if using darkmode, set to TRUE
#' @param debug logical. default FALSE
#' @param target_word specify the target word instead of choosing randomly.
#'        Useful for debugging.
#'
#' @export
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
play_wordle <- function(words = wordle_dict, dark_mode = TRUE, debug = FALSE, target_word = NULL) {
  game <- WordleGame$new(words, target_word = target_word)

  while (TRUE) {
    attempt <- readline("Enter your guess: ")
    res <- game$try(attempt)
    if (game$is_solved()) {
      cat("\nWell done! You cracked it!\n\n")
      game$share()
      break
    }
  }

}




if (FALSE) {

  game <- WordleGame$new(wordle_dict)
  game$try("paise")
  game$try("salon")
  game$is_solved()
  game$share()

}





