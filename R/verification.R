#' Dispatches execution to the most appropriate model verification function.
#'
#' @param x A model object.
#' @param newdata The verification dataset.
#' @param ... Arguments to pass on to the selected function.
verify = function(x, newdata, ...){
	UseMethod("verify")
}

#' Enhances a "glm" object with verification data.
#'
#' @param x A "glm" object.
#' @param newdata The verification dataset.
#' @param precision Maximal relative error.
#' @param zeroThreshold Maximal absolute error near the zero value.
#' @param ... Further arguments.
#'
#' @examples
#' library("mlbench")
#' library("r2pmml")
#'
#' data(BostonHousing)
#' housing.glm = glm(medv ~ ., data = BostonHousing, family = "gaussian")
#' housing.glm = verify(housing.glm, newdata = BostonHousing[sample(nrow(BostonHousing), 10), ])
#' r2pmml(housing.glm, file.path(tempdir(), "Housing-GLM-verified.pmml"))
verify.glm = function(x, newdata, precision = 1e-13, zeroThreshold = 1e-13, ...){
	active_values = newdata

	familyFamily = x$family$family

	target_values = NULL

	output_values = NULL

	if(familyFamily == "binomial"){
		responseIndex = attr(x$terms, "response")
		responseLevels = levels(x$model[[responseIndex]])

		response = predict(x, newdata = active_values, type = "response")

		prob = data.frame("0" = (1 - response), "1" = (response), check.names = FALSE)
		names(prob) = paste("probability(", responseLevels, ")", sep = "")

		output_values = prob
	} else

	{
		link = predict(x, newdata = active_values)

		target_values = data.frame(NULL = link)
	}

	x$verification = .makeVerification(precision, zeroThreshold, active_values, target_values, output_values)

	return (x)
}

#' Enhances a "train" object with verification data.
#'
#' @param x A "train" object.
#' @param newdata The verification dataset.
#' @param precision Maximal relative error.
#' @param zeroThreshold Maximal absolute error near the zero value.
#' @param ... Arguments to pass on to the "predict.train" method.
verify.train = function(x, newdata, precision = 1e-13, zeroThreshold = 1e-13, ...){
	ignore = function(cond){
	}

	active_values = newdata

	raw = predict(x, newdata = active_values, type = "raw", ...)

	target_values = data.frame(NULL = raw)

	output_values = NULL

	tryCatch({
		prob = predict(x, newdata = active_values, type = "prob", ...)
		names(prob) = paste("probability(", names(prob), ")", sep = "")

		output_values = prob
	}, error = ignore, warning = ignore)

	x$verification = .makeVerification(precision, zeroThreshold, active_values, target_values, output_values)

	return (x)
}

#' Enhances a model object with verification data.
#'
#' @param x A model object.
#' @param newdata The verification dataset.
#' @param ... Further arguments.
verify.default = function(x, newdata, ...){
	stop(paste("Verification is not implemented for", class(x)[[1]], sep = " "))
}

.makeVerification = function(precision, zeroThreshold, active_values, target_values, output_values = NULL){
	verification = list("precision" = precision, "zeroThreshold" = zeroThreshold, "active_values" = active_values, "target_values" = target_values, "output_values" = output_values)

	return (verification)
}
