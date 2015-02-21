r2pmml = function(model, file){
	tempfile = tempfile("r2pmml-", fileext = ".pb")

	con = file(tempfile, open = "wb")
	suppressWarnings(serialize_pb(model, con))
	close(con)

	tryCatch({.convert(tempfile, file)}, finally = {unlink(tempfile)})
}

.convert = function(pb_input, pmml_output){
	converter = .jnew("org/jpmml/converter/Main")
	.jcall(converter, "V", "setInput", .jnew("java/io/File", pb_input))
	.jcall(converter, "V", "setOutput", .jnew("java/io/File", pmml_output))
	.jcall(converter, "V", "run")
}