#' Dispatches execution to the most appropriate XGBoost feature map generation function.
#'
#' @param x A dataset object.
as.fmap = function(x){
	UseMethod("as.fmap")
}

#' Generates an XGBoost feature map based on feature data.
#'
#' @param df_X A "data.frame" object with independent variables.
#'
#' @return A "data.frame" object.
#'
#' @examples
#' data(iris)
#' iris.df = iris[, 1:4]
#' iris.fmap = as.fmap(iris.df)
as.fmap.data.frame = function(df_X){
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

	class(fmap) = c("fmap", class(fmap))
	row.names(fmap) = NULL

	return (fmap)
}

#' Generates an XGBoost feature map based on feature data.
#'
#' @param matrix_X A "matrix" object with independent variables.
#'
#' @return A "data.frame" object.
#'
#' @examples
#' data(iris)
#' iris.matrix = model.matrix(Species ~ . - 1, data = iris)
#' iris.fmap = as.fmap(iris.matrix)
as.fmap.matrix = function(matrix_X){
	cat_features = list()
	contrasts = attr(matrix_X, "contrasts")
	if(!is.null(contrasts)){
		contrast2features = function(contrasts, name){
			x = contrasts[[name]]
			if(!identical(rownames(x), colnames(x))){
				stop()
			}
			keys = lapply(colnames(x), FUN = function(level){ paste(name, level, sep = "") })
			values = lapply(colnames(x), FUN = function(level){ paste(name, "=", level, sep = "") })
			dict = c(values)
			names(dict) = keys
			return (dict)
		}
		for(name in names(contrasts)){
			features = contrast2features(contrasts, name)
			cat_features = append(cat_features, features)
		}
	}

	feature_names = list()
	feature_types = list()

	for(name in colnames(matrix_X)){
		cat_feature = cat_features[[name]]

		if(!is.null(cat_feature)){
			feature_names = append(feature_names, cat_feature)
			feature_types = append(feature_types, "i")
		} else

		{
			feature_names = append(feature_names, name)
			feature_types = append(feature_types, "q")
		}
	}

	fmap = data.frame("name" = unlist(feature_names), "type" = unlist(feature_types))
	fmap = cbind("id" = seq(from = 0, to = (nrow(fmap) - 1)), fmap)

	class(fmap) = c("fmap", class(fmap))
	row.names(fmap) = NULL

	return (fmap)
}

#' Writes XGBoost feature map to a file.
#'
#' @param fmap An XGBoost feature map as a "data.frame" object.
#' @param file A filesystem path to the result file.
write.fmap = function(fmap, file){
	write.table(fmap, file, sep = "\t", quote = FALSE, row.names = FALSE, col.names = FALSE)
}
