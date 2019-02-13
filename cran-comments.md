## Test environments
* Local GNU/Linux install, R 3.3.1
* Local GNU/Linux install, R 3.4.4
* Local GNU/Linux install, R 3.5.2
* Win-builder (devel and release)

## R CMD check results
There were no ERRORs or WARNINGs.

There was 1 NOTE:

* checking installed package size ...
  installed size is  5.3Mb
  sub-directories of 1Mb or more:
    java 5.2Mb

  The JPMML-R library depends on a number
  third-party Java libraries for PMML generation
  and marshalling. Excluding these libraries
  would break the package functionality.
  Re-packaging/filtering these libraries could
  make the package unstable as not all code paths
  are known at the compile time.
  The package size should stay under 6Mb in the
  foreseeable future.

## Downstream dependencies
There are currently no downstream dependencies for this package