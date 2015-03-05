r2pmml = function(x, file){
	tempfile = tempfile("r2pmml-", fileext = ".pb")

	main = function(){
		saveProtoBuf(x, tempfile)

		.convert(tempfile, file)
	}

	tryCatch({ main() }, finally = { unlink(tempfile) })
}

.convert = function(pb_input, pmml_output){
	converter = .jnew("org/jpmml/converter/Main")
	.jcall(converter, "V", "setInput", .jnew("java/io/File", pb_input))
	.jcall(converter, "V", "setOutput", .jnew("java/io/File", pmml_output))
	.jcall(converter, "V", "run")
}