R2PMML
======

R package for converting [R](https://www.r-project.org/) models to PMML

# Features #

This library is a thin wrapper around the JPMML-R command-line application.

For a list of supported model and transformation types, please refer to [JPMML-R features](https://github.com/jpmml/jpmml-r#features).

# Prerequisites #

* Java 1.8 or newer. The Java executable must be available on system path.

# Installation #

Installing a release version from CRAN:

```R
install.packages("r2pmml")
```

Alternatively, installing the latest snapshot version from GitHub using the [`devtools`](https://cran.r-project.org/package=devtools) package:

```R
library("devtools")

install_git("git://github.com/jpmml/r2pmml.git")
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

# Train a model using raw Iris dataset
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

# Use the preprocessor to transform raw Iris dataset to pre-processed Iris dataset
iris.transformed = predict(iris.preProcess, newdata = iris)

# Train a model using pre-processed Iris dataset
iris.rf = randomForest(Species ~., data = iris.transformed, ntree = 7)
print(iris.rf)

# Export the model to PMML.
# Pass the preprocessor as the `preProcess` argument
r2pmml(iris.rf, "iris_rf.pmml", preProcess = iris.preProcess)
```

### Model formulae

Alternatively, it is possible to associate `lm`, `glm` and `randomForest` models with data pre-processing transformations using [model formulae](https://stat.ethz.ch/R-manual/R-devel/library/stats/html/formula.html).

Training and exporting a `glm` model:

```R
library("plyr")
library("r2pmml")

# Load and prepare the Auto-MPG dataset
auto = read.table("http://archive.ics.uci.edu/ml/machine-learning-databases/auto-mpg/auto-mpg.data", quote = "\"", header = FALSE, na.strings = "?", row.names = NULL, col.names = c("mpg", "cylinders", "displacement", "horsepower", "weight", "acceleration", "model_year", "origin", "car_name"))
auto$origin = as.factor(auto$origin)
auto$car_name = NULL
auto = na.omit(auto)

# Train a model
auto.glm = glm(mpg ~ (. - horsepower - weight - origin) ^ 2 + I(displacement / cylinders) + cut(horsepower, breaks = c(0, 50, 100, 150, 200, 250)) + I(log(weight)) + revalue(origin, replace = c("1" = "US", "2" = "Europe", "3" = "Japan")), data = auto)

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
# Pass the training dataset as the `data` argument
r2pmml(iris.ranger, "iris_ranger.pmml", data = iris)
```

### Package `xgboost`

Training and exporting an `xgb.Booster` model:

```R
library("xgboost")
library("r2pmml")

data(iris)

iris_X = iris[, 1:4]
iris_y = as.integer(iris[, 5]) - 1

# Generate XGBoost feature map
iris.fmap = genFMap(iris_X)

# Generate XGBoost DMatrix
iris.DMatrix = genDMatrix(iris_y, iris_X)

# Train a model
iris.xgb = xgboost(data = iris.DMatrix, missing = NULL, objective = "multi:softmax", num_class = 3, nrounds = 13)

# Export the model to PMML.
# Pass the feature map as the `fmap` argument.
# Pass the name and category levels of the target field as `response_name` and `response_levels` arguments, respectively.
# Pass the value of missing value as the `missing` argument
# Pass the optimal number of trees as the `ntreelimit` argument (analogous to the `ntreelimit` argument of the `xgb::predict.xgb.Booster` function)
r2pmml(iris.xgb, "iris_xgb.pmml", fmap = iris.fmap, response_name = "Species", response_levels = c("setosa", "versicolor", "virginica"), missing = NULL, ntreelimit = 7, compact = TRUE)
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

R2PMML is dual-licensed under the [GNU Affero General Public License (AGPL) version 3.0](https://www.gnu.org/licenses/agpl-3.0.html), and a commercial license.

# Additional information #

R2PMML is developed and maintained by Openscoring Ltd, Estonia.

Interested in using JPMML software in your application? Please contact [info@openscoring.io](mailto:info@openscoring.io)
