r2pmml = function(model, file){
	tempfile = tempfile("r2pmml-", fileext = ".pb")

	con = file(tempfile, open = "wb")
	serialize_pb(rf, con)
	close(con)

	converter = .jnew("org/jpmml/converter/Main")
	.jcall(converter, "V", "setInput", .jnew("java/io/File", tempfile))
	.jcall(converter, "V", "setOutput", .jnew("java/io/File", file))
	.jcall(converter, "V", "run")

	unlink(tempfile)
}
