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
#' \donttest{
#' library("mlbench")
#' library("r2pmml")
#'
#' data(BostonHousing)
#' housing.glm = glm(medv ~ ., data = BostonHousing, family = "gaussian")
#' housing.glm = verify(housing.glm, newdata = BostonHousing[sample(nrow(BostonHousing), 10), ])
#' r2pmml(housing.glm, file.path(tempdir(), "Housing-GLM-verified.pmml"))
#' }
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

	return(x)
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

	return(x)
}

#' Enhances an "xgb.Booster" object with verification data.
#'
#' @param x An "xgb.Booster" object.
#' @param newdata The verification dataset.
#' @param precision Maximal relative error.
#' @param zeroThreshold Maximal absolute error near the zero value.
#' @param response_name The name of the target field.
#' @param response_levels A list of category values for a categorical target field.
#' @param ... Arguments to pass on to the "predict.xgb.Booster" method.
verify.xgb.Booster = function(x, newdata, precision = 1e-6, zeroThreshold = 1e-6, response_name = NULL, response_levels = c(), ...){
	active_values = NULL

	if(is(newdata, "Matrix")){
		active_values = as.data.frame(as.matrix(newdata))
	} else

	{
		active_values = as.data.frame(newdata)
	} # End if

	if(is.list(x) && "ptr" %in% names(x)){
		objective = attr(x, "params")[["objective"]]
	} else

	{
		objective = x$params$objective
	}

	target_values = NULL

	output_values = NULL

	if(objective == "reg:linear" || objective == "reg:squarederror" || objective == "reg:squaredlogerror" || objective == "reg:logistic"){
		response = predict(x, newdata = newdata, ...)

		response = as.data.frame(response)
		names(response) = response_name

		target_values = response
	} else

	if(objective == "binary:logistic"){
		prob = predict(x, newdata = newdata, ...)
		prob = matrix(c(1 - prob, prob), nrow = length(prob), ncol = 2)

		prob = as.data.frame(prob)
		names(prob) = paste("probability(", response_levels, ")", sep = "")

		output_values = prob
	} else

	if(objective == "multi:softmax"){
		response = predict(x, newdata = newdata, ...)

		response = as.data.frame(response)
		names(response) = response_name

		target_values = response
	} else

	if(objective == "multi:softprob"){
		prob = predict(x, newdata = newdata, reshape = TRUE, ...)

		prob = as.data.frame(prob)
		names(prob) = paste("probability(", response_levels, ")", sep = "")

		output_values = prob
	} else

	{
		stop(paste("Verification is not implemented for", objective, "objective function", sep = " "))
	}

	verification = .makeVerification(precision, zeroThreshold, active_values, target_values, output_values)

	if(is.list(x) && "ptr" %in% names(x)){
		# Assign as attribute
		attr(x, "verification") = verification
	} else

	{
		# Assign as element
		x$verification = verification
	}

	return(x)
}

#' Enhances a model object with verification data.
#'
#' @param x A model object.
#' @param newdata The verification dataset.
#' @param ... Further arguments.
verify.default = function(x, newdata, ...){
	stop(paste("Verification is not implemented for", class(x)[[1]], "class", sep = " "))
}

.makeVerification = function(precision, zeroThreshold, active_values, target_values, output_values = NULL){
	verification = list("precision" = precision, "zeroThreshold" = zeroThreshold, "active_values" = active_values, "target_values" = target_values, "output_values" = output_values)

	return(verification)
}
