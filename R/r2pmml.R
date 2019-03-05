#' Converts an R model object to PMML.
#'
#' @param x An R model object.
#' @param file A filesystem path to the result file.
#' @param converter The name of a custom JPMML-R converter class.
#' @param converter_classpath A list of filesystem paths to library JAR files that provide and support the custom JPMML-R converter class.
#' @param verbose A flag controlling the verbosity of the conversion process.
#' @param ... Arguments to be passed on to the "r2pmml::decorate" function.
#'
#' @examples
#' library("mlbench")
#' library("randomForest")
#' library("r2pmml")
#'
#' data(iris)
#' iris.rf = randomForest(Species ~ ., data = iris, ntree = 7)
#' # Convert "randomForest" object to R-style (deep binary splits) MiningModel
#' pmmlFile = file.path(tempdir(), "Iris-RandomForest.pmml")
#' r2pmml(iris.rf, pmmlFile)
#' # Convert "randomForest" object to PMML-style (shallow multi-way splits) MiningModel
#' compactPmmlFile = file.path(tempdir(), "Iris-RandomForest-compact.pmml")
#' r2pmml(iris.rf, compactPmmlFile, compact = TRUE)
#'
#' data(BostonHousing)
#' housing.glm = glm(medv ~ ., data = BostonHousing, family = "gaussian")
#' # Convert "glm" object into GeneralRegressionModel
#' genRegPmmlFile = file.path(tempdir(), "Housing-GLM.pmml")
#' r2pmml(housing.glm, genRegPmmlFile)
#' # Convert "glm" object into RegressionModel
#' regPmmlFile = file.path(tempdir(), "Housing-LM.pmml")
#' r2pmml(housing.glm, regPmmlFile, converter = "org.jpmml.rexp.LMConverter")
r2pmml = function(x, file, converter = NULL, converter_classpath = NULL, verbose = FALSE, ...){
	x = decorate(x, ...)

	tempfile = tempfile("r2pmml-", fileext = ".rds")

	main = function(){
		saveRDS(x, tempfile, version = 2)

		.convert(tempfile, file, converter, converter_classpath, verbose)
	}

	tryCatch({ main() }, finally = { unlink(tempfile) })
}

.classpath = function(){
	pkgs = installed.packages()

	pkg.r2pmml = pkgs["r2pmml", ]

	java_dir = file.path(pkg.r2pmml["LibPath"], pkg.r2pmml["Package"], "java")

	jar_files = list.files(path = java_dir, pattern = "*.jar", full.names = TRUE)

	return (paste(jar_files, collapse = .Platform$path.sep))
}

.convert = function(rds_input, pmml_output, converter = NULL, converter_classpath = NULL, verbose = FALSE){
	classpath = .classpath()

	if(!is.null(converter) && !is.null(converter_classpath)){

		if(length(converter_classpath) > 1){
			converter_classpath = paste(converter_classpath, collapse = .Platform$path.sep)
		}

		classpath = paste(classpath, converter_classpath, sep = .Platform$path.sep)
	}

	args = c("-cp", shQuote(classpath), "org.jpmml.rexp.Main", "--rds-input", shQuote(rds_input), "--pmml-output", shQuote(pmml_output))

	if(!is.null(converter)){
		args = c(args, "--converter", converter)
	}

	if(verbose){
		print(paste("java", paste(args, collapse = " "), sep = " "))
	}

	result = system2("java", args)
	if(result != 0){
		stop(result)
	}
}
