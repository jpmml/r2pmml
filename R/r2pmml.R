r2pmml = function(x, file, clean = TRUE){

	if(clean){
		x = .clean(x)
	}

	tempfile = tempfile("r2pmml-", fileext = ".pb")

	main = function(){
		saveProtoBuf(x, tempfile)

		.convert(tempfile, file)
	}

	tryCatch({ main() }, finally = { unlink(tempfile) })
}

.clean = function(x){

	if(is.null(x)){
		return (NULL)
	}

	attributes = attributes(x)

	if(is.environment(x) || is.language(x)){
		x = format(x)
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

.convert = function(pb_input, pmml_output){
	converter = .jnew("org/jpmml/converter/Main")
	.jcall(converter, "V", "setInput", .jnew("java/io/File", pb_input))
	.jcall(converter, "V", "setOutput", .jnew("java/io/File", pmml_output))
	.jcall(converter, "V", "run")
}