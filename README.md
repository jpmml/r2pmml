R2PMML
======

R package for converting R models to PMML

This package complements the standard [`pmml` package] (http://cran.r-project.org/web/packages/pmml/). This package can convert several model types that the standard `pmml` package cannot convert. The conversion is handled by the [JPMML-Converter] (https://github.com/jpmml/jpmml-converter) library, which delivers unmatched speed and memory efficiency. For example, this package can convert a typical `randomForest` model to a PMML file in a few seconds time, whereas the standard `pmml` package requires several hours to do the same.

# IMPORTANT #

![](https://github.com/jpmml/r2pmml/blob/master/bulb.png) Are you happy with our solution to your model deployment problem? Please show your support to this exciting technology **by voting** for our Hadoop Summit 2015 talk ["Rapid deployment of predictive models across Big Data platforms"] (https://hadoopsummit.uservoice.com/forums/283261-data-science-and-hadoop/suggestions/7074084). Thank you!

# Prerequisites #

* Java 1.7 or newer. The Java executable must be available on system path.

# Installation #

This package is not available in [CRAN] (http://cran.r-project.org/) yet.

Installing the package from its GitHub repository using the [`devtools` package] (http://cran.r-project.org/web/packages/devtools/):
```R
library("devtools")

install_github(repo = "jpmml/r2pmml")
```

This package depends on the following packages:
* [`rJava` package] (http://cran.r-project.org/web/packages/rJava/).
* [`RProtoBuf` package] (http://cran.r-project.org/web/packages/RProtoBuf/).

# Usage #

Loading the package:
```R
library("r2pmml")
```

The conversion is handled by the newly defined `r2pmml(obj, file)` function:
```R
library("randomForest")

data(iris)

rf = randomForest(Species ~ ., data = iris, n.tree = 7)
print(rf)

r2pmml(rf, "/tmp/rf.pmml")
```

When converting large files, then it may become necessary to increase JVM heap space by declaring the `java.parameters` option. Please note that this option must be declared **before** the `r2pmml` package (or any other package that depends on the `rJava` package) is loaded:
```R
options(java.parameters = c("-Xms4G", "-Xmx8G"))

library("r2pmml")
```

# Uninstallation #

Removing the package:
```R
remove.packages("r2pmml")
```

# License #

JPMML-Converter is dual-licensed under the [GNU Affero General Public License (AGPL) version 3.0] (http://www.gnu.org/licenses/agpl-3.0.html) and a commercial license.

# Additional information #

Please contact [info@openscoring.io] (mailto:info@openscoring.io)