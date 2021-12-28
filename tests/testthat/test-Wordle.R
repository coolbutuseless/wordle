test_that("Wordle works", {
  expect_equal(2 * 2, 4)


  wordle <- Wordle$new(nchar = 5)
  expect_true('eaten' %in% wordle$get_suggestions())

  wordle$update("eaten", c('yellow', 'grey', 'grey', 'grey', 'grey'))
  expect_true('rodeo' %in% wordle$get_suggestions())
})

