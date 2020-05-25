library("mlbench")
library("testthat")

source("../../R/xgboost.R")

data(iris)

check_iris_fmap = function(fmap){
	test_that("FMap dimensions", {
		expect_equal(c("fmap", "data.frame"), class(fmap))
		expect_equal(4, nrow(fmap))
		expect_equal(c("id", "name", "type"), colnames(fmap))
	})
	test_that("FMap content", {
		expect_equal(c(0, 1, 2, 3), fmap$id)
		expect_equal(c("Sepal.Length", "Sepal.Width", "Petal.Length", "Petal.Width"), as.character(fmap$name))
		expect_equal(c("q", "q", "q", "q"), as.character(fmap$type))
	})
}

iris.df = iris[, 1:4]
iris.df.fmap = as.fmap(iris.df)
check_iris_fmap(iris.df.fmap)

# Without LHS
iris.mf = model.frame("~ Sepal.Length + Sepal.Width + Petal.Length + Petal.Width - 1", data = iris)
iris.mf.fmap = as.fmap(iris.mf)
check_iris_fmap(iris.mf.fmap)

expect_equal(iris.df.fmap, iris.mf.fmap)

# With LHS
iris.mf = model.frame(Species ~ . - 1, data = iris)
iris.mf.fmap = as.fmap(iris.mf)
check_iris_fmap(iris.mf.fmap)

expect_equal(iris.df.fmap, iris.mf.fmap)

iris.matrix = model.matrix(Species ~ . - 1, data = iris)
iris.matrix.fmap = as.fmap(iris.matrix)
check_iris_fmap(iris.matrix.fmap)

expect_equal(iris.df.fmap, iris.matrix.fmap)

data(Ozone)

check_ozone_fmap = function(fmap){
	test_that("FMap dimensions", {
		expect_equal(c("fmap", "data.frame"), class(fmap))
		expect_equal(51, nrow(fmap))
		expect_equal(c("id", "name", "type"), colnames(fmap))
	})
	test_that("FMap content", {
		row = fmap[13, ]
		expect_equal(12, row$id)
		expect_equal("V2=1", as.character(row$name))
		expect_equal("i", as.character(row$type))
		row = fmap[51, ]
		expect_equal(50, row$id)
		expect_equal("V5", as.character(row$name))
		expect_equal("q", as.character(row$type))
	})
}

ozone.df = Ozone[, c("V1", "V2", "V3", "V5")]
ozone.df.fmap = as.fmap(ozone.df)
check_ozone_fmap(ozone.df.fmap)

# Without LHS
ozone.mf = model.frame(~ V1 + V2 + V3 + V5 - 1, data = Ozone, na.action = na.pass)
ozone.mf.fmap = as.fmap(ozone.mf)
check_ozone_fmap(ozone.mf.fmap)

expect_equal(ozone.df.fmap, ozone.mf.fmap)

# With LHS
ozone.mf = model.frame(V4 ~ V1 + V2 + V3 + V5 - 1, data = Ozone, na.action = na.pass)
ozone.mf.fmap = as.fmap(ozone.mf)
check_ozone_fmap(ozone.mf.fmap)

expect_equal(ozone.df.fmap, ozone.mf.fmap)

ozone.contrasts = lapply(Ozone[sapply(Ozone, is.factor)], contrasts, contrasts = FALSE)

ozone.matrix = model.matrix(V4 ~ V1 + V2 + V3 + V5 - 1, data = Ozone, contrasts.arg = ozone.contrasts)
ozone.matrix.fmap = as.fmap(ozone.matrix)
check_ozone_fmap(ozone.matrix.fmap)

expect_equal(ozone.df.fmap, ozone.matrix.fmap)
