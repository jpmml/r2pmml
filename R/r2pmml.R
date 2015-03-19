r2pmml = function(x, file, converter = NULL, clean = TRUE){

	if(clean){
		x = .clean(x)
	}

	tempfile = tempfile("r2pmml-", fileext = ".pb")

	main = function(){
		saveProtoBuf(x, tempfile)

		.convert(tempfile, file, converter)
	}

	tryCatch({ main() }, finally = { unlink(tempfile) })
}

.clean = function(x){

	if(is.null(x)){
		return (NULL)
	}

	attributes = attributes(x)

	if(is.environment(x) || is.function(x) || is.language(x)){
		x = format(x)
	}

	if(isS4(x)){
		classes = class(x)

		slotNames = slotNames(x)
		x = lapply(slotNames, function(slotName){ slot(x, slotName) })

		# The 'names' attribute will be (re-)set in the very end of this function
		attributes = c(attributes, "names" = list(slotNames))

		class(x) = classes
	}

	if(is.list(x)){
		classes = class(x)

		x = lapply(x, FUN = .clean)

		class(x) = classes
	}

	if(!is.null(attributes)){
		attributes(x) = lapply(attributes, FUN = .clean)
	}

	return (x)
}

.convert = function(pb_input, pmml_output, converter = NULL){
	main = .jnew("org/jpmml/converter/Main")

	.jcall(main, "V", "setInput", .jnew("java/io/File", pb_input))
	.jcall(main, "V", "setOutput", .jnew("java/io/File", pmml_output))

	if(!is.null(converter)){
		.jcall(main, "V", "setConverter", converter)
	}

	.jcall(main, "V", "run", check = FALSE)

	.jcheck()
}