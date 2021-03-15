#' Dispatches execution to the most appropriate XGBoost feature map generation function.
#'
#' @param x A dataset object.
as.fmap = function(x){
	UseMethod("as.fmap")
}

#' Generates an XGBoost feature map based on feature data.
#'
#' @param x A "data.frame" object with independent variables.
#'
#' @return A "data.frame" object.
#'
#' @examples
#' data(iris)
#' iris.df = iris[, 1:4]
#' iris.fmap = as.fmap(iris.df)
as.fmap.data.frame = function(x){
	feature_names = list()
	feature_types = list()

	names = colnames(x)

	terms = attr(x, "terms")
	if(!is.null(terms)){
		names = attr(terms, "term.labels")
	}

	for(name in names){
		col = x[[name]]

		if(is.factor(col)){
			feature_names = append(feature_names, lapply(levels(col), FUN = function(level){ paste(name, "=", level, sep = "") }))
			feature_types = append(feature_types, rep("i", length(levels(col))))
		} else

		if(is.integer(col)){
			feature_names = append(feature_names, name)
			feature_types = append(feature_types, "int")
		} else

		if(is.numeric(col)){
			feature_names = append(feature_names, name)
			feature_types = append(feature_types, "q")
		} else

		{
			stop()
		}
	}

	fmap = .makeFMap(feature_names, feature_types)

	return(fmap)
}

#' Generates an XGBoost feature map based on feature data.
#'
#' @param x A "matrix" object with independent variables.
#'
#' @return A "data.frame" object.
#'
#' @examples
#' data(iris)
#' iris.matrix = model.matrix(Species ~ . - 1, data = iris)
#' iris.fmap = as.fmap(iris.matrix)
as.fmap.matrix = function(x){
	cat_features = list()

	contrasts = attr(x, "contrasts")
	if(!is.null(contrasts)){
		contrast2features = function(contrasts, name){
			mat = contrasts[[name]]
			if(!identical(rownames(mat), colnames(mat))){
				stop()
			}
			keys = lapply(colnames(mat), FUN = function(level){ paste(name, level, sep = "") })
			values = lapply(colnames(mat), FUN = function(level){ paste(name, "=", level, sep = "") })
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

	for(name in colnames(x)){
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

	fmap = .makeFMap(feature_names, feature_types)

	return(fmap)
}

#' Writes XGBoost feature map to a file.
#'
#' @param fmap An XGBoost feature map as a "data.frame" object.
#' @param file A filesystem path to the result file.
write.fmap = function(fmap, file){
	write.table(fmap, file, sep = "\t", quote = FALSE, row.names = FALSE, col.names = FALSE)
}

.makeFMap = function(feature_names, feature_types){
	fmap = data.frame("name" = unlist(feature_names), "type" = unlist(feature_types))
	fmap = cbind("id" = seq(from = 0, to = (nrow(fmap) - 1)), fmap)

	fmap$id = as.integer(fmap$id)
	fmap$name = as.factor(fmap$name)
	fmap$type = as.factor(fmap$type)

	class(fmap) = c("fmap", class(fmap))
	row.names(fmap) = NULL

	return(fmap)
}