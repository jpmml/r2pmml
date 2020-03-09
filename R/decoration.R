#' Dispatches execution to the most appropriate model decoration function.
#'
#' @param x A model object.
#' @param ... Arguments to pass on to the selected function.
decorate = function(x, ...){
	UseMethod("decorate")
}

#' Decorates an "earth" object with an "xlevels" element.
#'
#' @param x An "earth" object.
#' @param data The training dataset.
#' @param ... Arguments to pass on to the "decorate.default" function.
decorate.earth = function(x, data, ...){

	if(is.null(x$xlevels)){
		x$xlevels = .getFactorLevels(data)
	}

	decorate.default(x, ...)
}

#' Decorates an "elmNN" object with a "model" element.
#'
#' @param x An "elmNN" object.
#' @param data The training dataset.
#' @param ... Arguments to pass on to the "decorate.default" function.
decorate.elmNN = function(x, data, ...){

	if(is.null(x$model)){
		x$model = model.frame(x$formula, data = data)

		mmat = model.matrix(x$model, data = x$model)
		attr(attr(x$model, "terms"), "columns") = colnames(mmat)
	}

	decorate.default(x, ...)
}

#' Decorates a "glmnet" object with a "lambda.s" element.
#'
#' @param x A "glmnet" object.
#' @param lambda.s The best lambda value. Must be one of listed "glmnet$lambda" values.
#' @param ... Arguments to pass on to the "decorate.default" function.
#'
#' @examples
#' \donttest{
#' library("glmnet")
#' library("r2pmml")
#'
#' data(iris)
#' iris_x = as.matrix(iris[, -ncol(iris)])
#' iris_y = iris[, ncol(iris)]
#' iris.glmnet = glmnet(x = iris_x, y = iris_y, family = "multinomial")
#' iris.glmnet = decorate(iris.glmnet, lambda.s = iris.glmnet$lambda[49])
#' r2pmml(iris.glmnet, file.path(tempdir(), "Iris-GLMNet.pmml"))
#' }
decorate.glmnet = function(x, lambda.s, ...){

	if(is.null(x$lambda.s)){
		x$lambda.s = lambda.s
	}

	decorate.default(x, ...)
}

#' Decorates a "party" object with a "predicted" element.
#'
#' @param x A "party" object.
#' @param ... Arguments to pass on to the "decorate.default" function.
#'
#' @examples
#' \donttest{
#' library("evtree")
#' library("r2pmml")
#'
#' data(iris)
#' iris.party = evtree(Species ~ ., data = iris,
#'     control = evtree.control(max_depth = 3))
#' iris.party = decorate(iris.party)
#' r2pmml(iris.party, file.path(tempdir(), "Iris-Party.pmml"))
#' }
decorate.party = function(x, ...){

	if(is.null(x$predicted)){
		predicted = list()

		ids = 1:length(x)

		predicted$"(response)" = partykit::predict_party(x, id = ids, type = "response")
		if(is.factor(predicted$"(response)")){
			predicted$"(prob)" = partykit::predict_party(x, id = ids, type = "prob")
		}

		x$predicted = predicted
	}

	decorate.default(x, ...)
}

#' Decorates a "randomForest" object with PMML conversion options.
#'
#' @param x A "randomForest" object.
#' @param compact A flag controlling if decision trees should be transformed from binary splits (FALSE) to multi-way splits (TRUE) representation.
#' @param ... Arguments to pass on to the "decorate.default" function.
decorate.randomForest = function(x, compact = FALSE, ...){
	decorate.default(x, pmml_options = list(compact = compact), ...)
}

#' Decorates a "ranger" object with a "variable.levels" element.
#'
#' @param x A "ranger" object.
#' @param data The training dataset.
#' @param ... Arguments to pass on to the "decorate.default" function.
#'
#' @examples
#' \donttest{
#' library("ranger")
#' library("r2pmml")
#'
#' data(iris)
#' iris.ranger = ranger(Species ~ ., data = iris, num.trees = 17,
#'     write.forest = TRUE, probability = TRUE)
#' iris.ranger = decorate(iris.ranger, data = iris)
#' r2pmml(iris.ranger, file.path(tempdir(), "Iris-Ranger.pmml"))
#' }
decorate.ranger = function(x, data, ...){

	if(is.null(x$variable.levels)){
		x$variable.levels = .getFactorLevels(data)
	}

	decorate.default(x, ...)
}

#' Decorates a "svm.formula" object with an "xlevels" element.
#'
#' @param x A "svm.formula" object.
#' @param data The training dataset.
#' @param ... Arguments to pass on to the "decorate.default" function.
decorate.svm.formula = function(x, data, ...){

	if(is.null(x$xlevels)){
		x$xlevels = .getFactorLevels(data)
	}

	decorate.default(x, ...)
}

#' Decorates the final model of a "train" object with model type-dependent elements.
#'
#' @param x A "train" object.
#' @param ... Arguments to pass on to the "decorate.default" function.
decorate.train = function(x, ...){
	x$finalModel = decorate(x$finalModel, preProcess = NULL, ...)

	return (x)
}

#' Decorates a "WrappedModel" object with "invert_levels" element.
#' Additionally, decorates the learned model with model type-dependent elements.
#'
#' @param x A "WrappedModel" object.
#' @param invert_levels A flag indicating if the learned model should assume normal (FALSE) or inverted (TRUE) ordering of category values for the binary categorical target field.
#' @param ... Arguments to pass on to the "decorate.default" function
decorate.WrappedModel = function(x, invert_levels = FALSE, ...){
	task.desc = x$task.desc

	if(task.desc$type == "classif" && length(task.desc$class.levels) == 2){
		x$invert_levels = invert_levels
	}

	x$learner.model = decorate(x$learner.model, ...)

	return (x)
}

#' Decorates an "xgb.Booster" object with "fmap", "schema", "ntreelimit" and "pmml_options" elements.
#'
#' @param x An "xgb.Booster" object.
#' @param fmap An XGBoost feature map as a "data.frame" object.
#' @param response_name The name of the target field.
#' @param response_levels A list of category values for a categorical target field.
#' @param missing The string representation of missing input field values.
#' @param ntreelimit The number of decision trees (aka boosting rounds) to convert.
#' @param compact A flag controlling if decision trees should be transformed from binary splits (FALSE) to multi-way splits (TRUE) representation.
#' @param ... Arguments to pass on to the "decorate.default" function.
#'
#' @examples
#' \donttest{
#' library("xgboost")
#' library("r2pmml")
#'
#' data(iris)
#' iris_x = iris[, -ncol(iris)]
#' iris_y = iris[, ncol(iris)]
#' # Convert from factor to integer[0, num_class]
#' iris_y = (as.integer(iris_y) - 1)
#' iris.fmap = as.fmap(iris_x)
#' iris.dmatrix = genDMatrix(iris_y, iris_x)
#' iris.xgboost = xgboost(data = iris.dmatrix, 
#'     objective = "multi:softprob", num_class = 3, nrounds = 11)
#' iris.xgboost = decorate(iris.xgboost, iris.fmap, 
#'     response_name = "Species", response_levels = c("setosa", "versicolor", "virginica"))
#' pmmlFile = file.path(tempdir(), "Iris-XGBoost.pmml")
#' r2pmml(iris.xgboost, pmmlFile, compact = FALSE)
#' compactPmmlFile = file.path(tempdir(), "Iris-XGBoost-compact.pmml")
#' r2pmml(iris.xgboost, compactPmmlFile, compact = TRUE)
#' }
decorate.xgb.Booster = function(x, fmap, response_name = NULL, response_levels = c(), missing = NULL, ntreelimit = NULL, compact = FALSE, ...){

	if(is.null(x$fmap)){
		x$fmap = fmap
	}

	if(is.null(x$schema)){
		schema = list()

		if(!is.null(response_name)){
			schema$response_name = response_name
		}

		if(length(response_levels) > 0){
			schema$response_levels = response_levels
		}

		if(!is.null(missing)){
			schema$missing = missing
		}

		if(length(schema) > 0){
			x$schema = schema
		}
	}

	if(is.null(x$ntreelimit)){
		x$ntreelimit = ntreelimit
	}

	decorate.default(x, pmml_options = list(compact = compact), ...)
}

#' Decorates a model object with "preProcess" and "pmml_options" elements.
#'
#' @param x The model object.
#' @param preProcess A "train::preProcess" object.
#' @param pmml_options A list of model type-dependent PMML conversion options.
#' @param ... Further arguments.
decorate.default = function(x, preProcess = NULL, pmml_options = NULL, ...){

	if(!is.null(preProcess)){
		x$preProcess = preProcess
	}

	if(!is.null(pmml_options)){
		x$pmml_options = pmml_options
	}

	return (x)
}

.getFactorLevels = function(data){
	levels = lapply(data, function(x){ if(is.factor(x)) { levels(x) } else { NULL }})

	return (levels[!vapply(levels, is.null, NA)])
}
