r2pmml = function(x, ...){
	UseMethod("r2pmml")
}

r2pmml.ranger = function(x, variable.levels, file, ...){
	x$variable.levels = variable.levels

	r2pmml.default(x, file, ...)
}

r2pmml.xgb.Booster = function(x, fmap, file, response_name = NA, response_levels = c(), missing = NA, ...){
	x$fmap = fmap

	schema = list()

	if(!is.na(response_name)){
		schema$response_name = response_name
	}

	if(length(response_levels) > 0){
		schema$response_levels = response_levels
	}

	if(!is.na(missing)){
		schema$missing = missing
	}

	if(length(schema) > 0){
		x$schema = schema
	}

	r2pmml.default(x, file, ...)
}

r2pmml.default = function(x, file, dataset = NULL, preProcess = NULL, ...){

	if(!is.null(preProcess)){
		x$preProcess = preProcess
	}

	tempfile = tempfile("r2pmml-", fileext = ".rds")

	main = function(){
		saveRDS(x, tempfile)

		.convert(tempfile, file, ...)
	}

	tryCatch({ main() }, finally = { unlink(tempfile) })
}

.classpath = function(){
	pkgs = installed.packages()

	pkg.r2pmml = pkgs["r2pmml", ]

	java_dir = file.path(pkg.r2pmml["LibPath"], pkg.r2pmml["Package"], "java", fsep = .Platform$file.sep)

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
