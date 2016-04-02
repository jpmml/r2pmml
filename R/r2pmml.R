r2pmml = function(x, ...){
	UseMethod("r2pmml")
}

r2pmml.xgb.Booster = function(x, fmap, file, converter = NULL){
	x$fmap = fmap

	r2pmml.default(x, file, converter)
}

r2pmml.default = function(x, file, converter = NULL){
	tempfile = tempfile("r2pmml-", fileext = ".rds")

	main = function(){
		saveRDS(x, tempfile)

		.convert(tempfile, file, converter)
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

.convert = function(rds_input, pmml_output, converter = NULL){
	args = c(getOption("java.parameters", default = character()), "-cp", .classpath(), "org.jpmml.rexp.Main", "--rds-input", rds_input, "--pmml-output", pmml_output)

	if(!is.null(converter)){
		args = c(args, "--converter", converter)
	}

	result = system2("java", args)
	if(result != 0){
		stop(result)
	}
}
