test_that("The class attribute is preserved", {
	classes = c("specific_class", "generic_class")

	x = structure(list(), class = classes)

	expect_true(is.list(x))
	expect_is(x, class = classes)

	x.rexp = .clean(x)

	expect_true(is.list(x.rexp))
	expect_is(x.rexp, class = classes)

	expect_equal(x.rexp, x)
})

test_that("The environment object is formatted as character", {
	x = environment()

	expect_true(is.environment(x))

	x.rexp = .clean(x)

	expect_true(is.character(x.rexp))
})

test_that("The function object is formatted as character", {
	x = function(){ return (TRUE) }

	expect_true(is.function(x))

	x.rexp = .clean(x)

	expect_true(is.character(x.rexp))
})

test_that("The language object is formatted as character", {
	x = expression(list(1, 2, 3))

	expect_true(is.language(x))

	x.rexp = .clean(x)

	expect_true(is.character(x.rexp))
})

test_that("Environment fields and attributes are formatted as character", {
	x = list("env" = environment(), "child" = list("env" = environment()))

	expect_true(is.environment(x$env))
	expect_true(is.environment(x$child$env))

	attributes(x$child) = c(attributes(x$child), "env" = environment())

	expect_true(is.environment(attr(x$child, "env")))

	x.rexp = .clean(x)

	expect_true(is.character(x.rexp$env))
	expect_true(is.character(x.rexp$child$env))

	expect_true(is.character(attr(x.rexp$child, "env")))
})

test_that("The S4 object is formatted as S3 object", {
	setClass("Test", slots = c("env"))

	x = new("Test", env = environment())

	expect_true(isS4(x))
	expect_true(is.environment(x@env))
	expect_true(is.null(names(x)))

	x.rexp = .clean(x)

	expect_true(is.list(x.rexp))
	expect_true(is.character(x.rexp$env))
	expect_equal(names(x.rexp), c("env"))

	expect_equal(class(x), class(x.rexp))
})
