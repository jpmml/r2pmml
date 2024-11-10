#' Converts an R model object to PMML.
#'
#' @param x An R model object.
#' @param file A filesystem path to the result file.
#' @param schema The PMML schema version for the PMML document.
#' @param converter The name of a custom JPMML-R converter class.
#' @param converter_classpath A list of filesystem paths to library JAR files that provide and support the custom JPMML-R converter class.
#' @param verbose A flag controlling the verbosity of the conversion process.
#' @param ... Arguments to be passed on to the "r2pmml::decorate" function.
#'
#' @examples
#' \donttest{
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
#' }
r2pmml = function(x, file, schema = NULL, converter = NULL, converter_classpath = NULL, verbose = FALSE, ...){
	x = decorate(x, ...)

	tempfile = tempfile("r2pmml-", fileext = ".rds")

	main = function(){
		saveRDS(x, tempfile, version = 2)

		.convert(rds_input = tempfile, pmml_output = file, pmml_schema = schema, converter = converter, converter_classpath = converter_classpath, verbose = verbose)
	}

	tryCatch({ main() }, finally = { unlink(tempfile) })
}

.classpath = function(){
	pkg.r2pmml = find.package("r2pmml")

	java_dir = file.path(pkg.r2pmml, "java")

	jar_files = readLines(file.path(java_dir, "classpath.txt"), encoding = "UTF-8", warn = FALSE)

	jar_files = sapply(jar_files, function(x){
		return(file.path(java_dir, x))
	})

	return(paste(jar_files, collapse = .Platform$path.sep))
}

.convert = function(rds_input, pmml_output, pmml_schema, converter, converter_classpath, verbose){
	classpath = .classpath()

	if(!is.null(converter) && !is.null(converter_classpath)){

		if(length(converter_classpath) > 1){
			converter_classpath = paste(converter_classpath, collapse = .Platform$path.sep)
		}

		classpath = paste(classpath, converter_classpath, sep = .Platform$path.sep)
	}

	args = c("-cp", shQuote(classpath), "com.r2pmml.Main", "--rds-input", shQuote(rds_input), "--pmml-output", shQuote(pmml_output))

	if(!is.null(pmml_schema)){
		args = c(args, "--pmml-schema", pmml_schema)
	}

	if(!is.null(converter)){
		args = c(args, "--converter", converter)
	}

	if(verbose){
		print(paste("java", paste(args, collapse = " "), sep = " "))
	}

	result = system2("java", args)

	if(result == 127){
		stop(c("Java is not installed, or the Java executable is not on system path (error code ", result, ")"));
	} else

	if(result != 0){
		stop(c("The R2PMML conversion application has failed (error code ", result, "). The Java executable should have printed more information about the failure into its standard output and/or standard error streams"))
	}
}
