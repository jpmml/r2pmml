r2pmml = function(x, file, converter = NULL){
	tempfile = tempfile("r2pmml-", fileext = ".rds")

	main = function(){
		saveRDS(x, tempfile)

		.convert(tempfile, file, converter)
	}

	tryCatch({ main() }, finally = { unlink(tempfile) })
}

.convert = function(pb_input, pmml_output, converter = NULL){
	main = .jnew("org/jpmml/rexp/Main")

	.jcall(main, "V", "setInput", .jnew("java/io/File", pb_input))
	.jcall(main, "V", "setOutput", .jnew("java/io/File", pmml_output))

	if(!is.null(converter)){
		.jcall(main, "V", "setConverter", converter)
	}

	.jcall(main, "V", "run", check = FALSE)

	.jcheck()
}