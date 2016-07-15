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

This package is not yet available in the [CRAN package repository] (http://cran.r-project.org/).

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

The conversion is handled by the `r2pmml(x, file, ...)` function:
```R
library("randomForest")

data(iris)

rf = randomForest(Species ~ ., data = iris, ntree = 7)
print(rf)

r2pmml(rf, "rf.pmml")
```

Upon invocation, the `r2pmml` function launches a new Java process using the [`system2`] (https://stat.ethz.ch/R-manual/R-devel/library/base/html/system2.html) function, and waits for it to finish.

### Advanced functionality

Tweaking JVM configuration:
```R
Sys.setenv(JAVA_TOOL_OPTIONS = "-Xms4G -Xmx8G")

r2pmml(rf, "rf.pmml")
```

Employing a custom converter class:
```R
r2pmml(rf, "rf.pmml", converter = "com.mycompany.MyRandomForestConverter", converter_classpath = "/path/to/myconverter-1.0-SNAPSHOT.jar")
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
