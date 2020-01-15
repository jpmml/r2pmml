#' Generates an XGBoost feature map based on feature data.
#'
#' @param df_X A "data.frame" object with independent variables.
#'
#' @return A "data.frame" object.
#'
#' @examples
#' data(iris)
#' iris.fmap = genFMap(iris[, 1:4])
genFMap = function(df_X){
	col2name = function(x){
		col = df_X[[x]]
		if(is.factor(col)){
			return (lapply(levels(col), FUN = function(level){ paste(x, "=", level, sep = "") }))
		}
		return (x)
	}
	feature_names = lapply(names(df_X), FUN = col2name)

	col2type = function(x){
		switch(class(x), "factor" = rep("i", length(levels(x))), "numeric" = "q", "integer" = "int")
	}
	feature_types = lapply(df_X, FUN = col2type)

	fmap = data.frame("name" = unlist(feature_names), "type" = unlist(feature_types))
	fmap = cbind("id" = seq(from = 0, to = (nrow(fmap) - 1)), fmap)

	return (fmap)
}

#' Writes XGBoost feature map to a file.
#'
#' @param fmap An XGBoost feature map as a "data.frame" object.
#' @param file A filesystem path to the result file.
writeFMap = function(fmap, file){
	write.table(fmap, file, sep = "\t", quote = FALSE, row.names = FALSE, col.names = FALSE)
}

#' Generates an XGBoost "DMatrix" object based on label and feature data.
#'
#' @param df_y A vector with dependent variable values.
#' @param df_X A "data.frame" object with independent variable values.
#' @param file A filesystem path for storing the temporary LibSVM data format file.
#'
#' @return An "xgb.DMatrix" object.
#'
#' @examples
#' data(iris)
#' iris.DMatrix = genDMatrix(as.integer(iris[, 5]) - 1, iris[, 1:4])
genDMatrix = function(df_y, df_X, file = tempfile(pattern = "DMatrix", fileext = ".libsvm")){
	col2len = function(x){
		col = df_X[[x]]
		if(is.factor(col)){
			return (length(levels(col)))
		}
		return (1)
	}
	col_len = sapply(names(df_X), FUN = col2len)
	col_offset = (cumsum(col_len) - col_len)

	factor2pos = function(x){
		if(is.na(x)){
			return (NA)
		}
		if(is.factor(x)){
			return (as.integer(x) - 1)
		}
		return (0)
	}

	format_cell = function(x){
		if(is.na(x)){
			return (NA)
		}
		if(is.factor(x)){
			return (1)
		}
		return (x)
	}

	fp = file(file, "w")

	for(i in 1:nrow(df_X)){
		cell_offset = (col_offset + sapply(df_X[i, ], FUN = factor2pos))
		cell_value = sapply(df_X[i, ], FUN = format_cell)

		y_value = df_y[i]
		X_values = paste(na.omit(cell_offset), na.omit(cell_value), sep = ":", collapse = " ")

		cat(paste(y_value, " ", X_values, "\n", sep = ""), file = fp)
	}

	close(fp)

	# XGBoost URI parser only accepts forward slashes (even on the Windows platform)
	xgbFile = gsub("\\", "/", file, fixed = TRUE)

	return (xgboost::xgb.DMatrix(xgbFile))
}
