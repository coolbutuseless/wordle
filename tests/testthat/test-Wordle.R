test_that("Wordle works", {
  expect_equal(2 * 2, 4)


  wordle <- WordleHelper$new(nchar = 5)
  expect_true('eaten' %in% wordle$words)

  wordle$update("eaten", c('yellow', 'grey', 'grey', 'grey', 'grey'))
  expect_true('rodeo' %in% wordle$words)
})


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# EATEN
# TORSO
# BOOST

# After playing 'EATEN' and 'TORSO', all suggestions
# should include two "O"s
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
test_that("Wordle detects duplicated latters", {

  wordle <- WordleHelper$new(5)
  wordle$words

  wordle$update(word = "eaten", response = c('grey', 'grey', 'yellow', 'grey', 'grey'))
  wordle$words

  wordle$update(word = "torso", response = c('yellow', 'green', 'grey', 'green', 'yellow'))
  res <- wordle$words

  double_ohs <- grepl("o.*o", res)
  expect_true(all(double_ohs))

})
