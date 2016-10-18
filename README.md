R2PMML
======

R package for converting R models to PMML

# Features #

This package complements the standard [`pmml` package] (http://cran.r-project.org/web/packages/pmml/):

* It supports several model types (eg. `gbm`, `iForest`, `ranger`, `xgb.Booster`) that are not supported by the standard `pmml` package.
* It is extremely fast and memory efficient. For example, it can convert a typical `randomForest` model to a PMML file in a few seconds time, whereas the standard `pmml` package requires several hours to do the same.

# Prerequisites #

* Java 1.7 or newer. The Java executable must be available on system path.

# Installation #

Installing the package from its GitHub repository using the [`devtools` package] (http://cran.r-project.org/web/packages/devtools/):
```R
library("devtools")

install_github(repo = "jpmml/r2pmml")
```

# Usage #

### Base functionality

Loading the package:
```R
library("r2pmml")
```

Training and exporting a simple `randomForest` model:
```R
library("randomForest")
library("r2pmml")

data(iris)

# Train a model using raw Iris data
iris.rf = randomForest(Species ~ ., data = iris, ntree = 7)
print(iris.rf)

# Export the model to PMML
r2pmml(iris.rf, "iris_rf.pmml")
```

### Data pre-processing

The `r2pmml` function takes an optional argument `preProcess`, which associates the model with data pre-processing transformations.

Training and exporting a more sophisticated `randomForest` model:
```R
library("caret")
library("randomForest")
library("r2pmml")

data(iris)

# Create a preprocessor
iris.preProcess = preProcess(iris, method = c("range"))

# Use the preprocessor to transform raw Iris data to pre-processed Iris data
iris.transformed = predict(iris.preProcess, newdata = iris)

# Train a model using pre-processed Iris data
iris.rf = randomForest(Species ~., data = iris.transformed, ntree = 7)
print(iris.rf)

# Export the model to PMML.
# Pass the preprocessor as the `preProcess` argument
r2pmml(iris.rf, preProcess = iris.preProcess, "iris_rf.pmml")
```

### Model formulae

Alternatively, it is possible to associate `lm` and `glm` models with data pre-processing transformations via [model formulae] (https://stat.ethz.ch/R-manual/R-devel/library/stats/html/formula.html).

Supported model formula features:

* Interaction terms.
* `I(..)` expression terms:
   * The `if` expression.
   * Logical operators `&`, `|` and `!`.
   * Relational operators `==`, `!=`, `<`, `<=`, `>=` and `>`.
   * Arithmetic operators: `+`, `-`, `/` and `*`.
   * Exponentiation operators `^` and `**`.
   * The `is.na` function.
   * Arithmetic functions `abs`, `ceiling`, `exp`, `floor`, `log`, `log10`, `round` and `sqrt`.

Training and exporting a `glm` model:
```R
library("r2pmml")

auto = read.table("http://archive.ics.uci.edu/ml/machine-learning-databases/auto-mpg/auto-mpg.data", quote = "\"", header = FALSE, na.strings = "?", row.names = NULL, col.names = c("mpg", "cylinders", "displacement", "horsepower", "weight", "acceleration", "model_year", "origin", "car_name"))
auto$origin = as.factor(auto$origin)
auto$car_name = NULL

# Remove NA rows
auto = na.omit(auto)

# Train a model.
# Use the `(..)^2` construct to define main effects for all features together with their second-order interactions.
# Use the `I(..)` construct to define two new features
auto.glm = glm(mpg ~ (.) ^ 2 + I(displacement / cylinders) + I(log(weight)), data = auto)

# Export the model to PMML
r2pmml(auto.glm, "auto_glm.pmml")
```

### Package `ranger`

Training and exporting a `ranger` model:
```R
library("ranger")
library("r2pmml")

data(iris)

# Train a model.
# Keep the forest data structure by specifying `write.forest = TRUE`
iris.ranger = ranger(Species ~ ., data = iris, num.trees = 7, write.forest = TRUE)
print(iris.ranger)

# Export the model to PMML.
# Pass the levels of all factor variables as the `variable.levels` argument
r2pmml(iris.ranger, variable.levels = sapply(iris, levels), "iris_ranger.pmml")
```

### Package `xgboost`

Training and exporting an `xgb.Booster` model:
```R
library("xgboost")
library("r2pmml")

data(iris)

iris_x = iris[, 1:4]
iris_y = as.integer(iris[, 5]) - 1

# Train a model
iris.xgb = xgboost(data = as.matrix(iris_x), label = iris_y, missing = NA, objective = "multi:softmax", num_class = 3, nrounds = 13)

# Create a feature map
iris.fmap = data.frame(
	"id" = seq(from = 0, (to = ncol(iris_x) - 1)),
	"name" = names(iris_x),
	"type" = rep("q", ncol(iris_x))
)

# Export the model to PMML.
# Pass the feature map as the `fmap` argument.
# Pass the name and category levels of the target field as `response_name` and `response_levels` arguments, respectively.
# Pass the value of missing value as the `missing` argument
r2pmml(iris.xgb, fmap = iris.fmap, response_name = "Species", response_levels = c("setosa", "versicolor", "virginica"), missing = NA, "iris_xgb.pmml")
```

### Advanced functionality

Tweaking JVM configuration:
```R
Sys.setenv(JAVA_TOOL_OPTIONS = "-Xms4G -Xmx8G")

r2pmml(iris.rf, "iris_rf.pmml")
```

Employing a custom converter class:
```R
r2pmml(iris.rf, "iris_rf.pmml", converter = "com.mycompany.MyRandomForestConverter", converter_classpath = "/path/to/myconverter-1.0-SNAPSHOT.jar")
```

# De-installation #

Removing the package:
```R
remove.packages("r2pmml")
```

# License #

R2PMML is licensed under the [GNU Affero General Public License (AGPL) version 3.0] (http://www.gnu.org/licenses/agpl-3.0.html). Other licenses are available on request.

# Additional information #

Please contact [info@openscoring.io] (mailto:info@openscoring.io)
