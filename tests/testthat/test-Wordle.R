test_that("Wordle works", {
  expect_equal(2 * 2, 4)


  wordle <- Wordle$new(nchar = 5)
  expect_true('eaten' %in% wordle$get_suggestions())

  wordle$update("eaten", c('yellow', 'grey', 'grey', 'grey', 'grey'))
  expect_true('rodeo' %in% wordle$get_suggestions())
})


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# EATEN
# TORSO
# BOOST

# After playing 'EATEN' and 'TORSO', all suggestions
# should include two "O"s
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
test_that("Wordle detects duplicated latters", {

  wordle <- Wordle$new(5)
  wordle$get_suggestions()

  wordle$update(word = "eaten", response = c('grey', 'grey', 'yellow', 'grey', 'grey'))
  wordle$get_suggestions()

  wordle$update(word = "torso", response = c('yellow', 'green', 'grey', 'green', 'yellow'))
  res <- wordle$get_suggestions()

  double_ohs <- grepl("o.*o", res)
  expect_true(all(double_ohs))

})
