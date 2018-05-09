verify = function(x, newdata, ...){
	UseMethod("verify")
}

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

verify.default = function(x, newdata){
	stop(paste("Verification is not implemented for", class(x)[[1]], sep = " "))
}

.makeVerification = function(precision, zeroThreshold, active_values, target_values, output_values = NULL){
	verification = list("precision" = precision, "zeroThreshold" = zeroThreshold, "active_values" = active_values, "target_values" = target_values, "output_values" = output_values)

	return (verification)
}
