saveProtoBuf = function(x, file){
	con = file(file, open = "wb")

	tryCatch({ suppressWarnings(serialize_pb(x, con)) }, finally = { close(con) })
}

readProtoBuf = function(file){
	con = file(file, open = "rb")

	result = tryCatch({ unserialize_pb(con) }, finally = { close(con) })

	return (result)
}