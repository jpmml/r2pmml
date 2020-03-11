#' Converts a "glm" object to a "scorecard" object.
#'
#' @param glm A "glm" object with binomial family link function.
#' @param odds Odds ratio at base odds.
#' @param base_points Points where odds ratio is defined.
#' @param pdo Points to double the odds.
#'
#' @return A "scorecard" object.
as.scorecard = function(glm, odds = 10, base_points = 500, pdo = 100){

	if(!inherits(glm, "glm")){
		stop("Not a glm object")
	} # End if

	if(glm$family$family != "binomial"){
		stop("Not a glm object with binomial family link function")
	}

	sc.conf = list()
	sc.conf$odds = odds
	sc.conf$base_points = base_points
	sc.conf$pdo = pdo

	class(glm) = c("scorecard", class(glm))

	glm$sc.conf = sc.conf

	return(glm)
}
