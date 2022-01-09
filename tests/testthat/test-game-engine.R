

test_that("game engine works", {

  game <- WordleGame$new(words = wordle_dict, target_word = 'essay')

  response <- game$try('sease', quiet = TRUE)
  expect_identical(response, c('yellow', 'yellow', 'yellow', 'yellow', 'grey'))

  response <- game$try('yield', quiet = TRUE)
  expect_identical(response, c('yellow', 'grey', 'yellow', 'grey', 'grey'))

  response <- game$try('fungi', quiet = TRUE)
  expect_identical(response, rep('grey', 5))


})
