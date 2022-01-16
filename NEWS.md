
# wordle 0.1.7  2022-01-16

* `play_wordle(debug = TRUE)` now outputs the target word at the start of the game
* Tidied `wordle_dict` such the answer set is no longer at the front of the list
* Split out `wordle_solns` which is a character vector of solutions to all 
  past and future puzzles
* Added `orthogonal_words`. These are sets of 1-to-5 words containing the 
  5-, 10-, 15-, 20-, all- most common letters without duplicate letters.


# wordle 0.1.6  2022-01-09

* add a `quiet` argument to `WordleGame$try()` to suppress output
* Fixed issue #1

# wordle 0.1.5  2022-01-04

* Remove the internal sorting mechanism - this is now the users responsibility
* Add a `WordleGame` `R6` class for running a game of Wordle
* Added a simple `play_wordle()` function to run the engine


# wordle 0.1.4  2022-01-04

* Export the `wordle_dict` list of words

# wordle 0.1.3  2022-01-04

* Include (and use by default) the 'official' wordle word list

# wordle 0.1.2  2022-01-03

* Switch to `stringi` for some string handling

# wordle 0.1.1  2022-01-02

* Internal refactor to fix bug for incorrect handling of `known_counts`

# wordle 0.1.0   2021-12-28

* Initial release
