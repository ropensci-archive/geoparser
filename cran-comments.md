## Test environments
- Local R version 3.6.0 Ubuntu 18.04.2 LTS  
- R-hub windows-x86_64-devel (r-devel)
- R-hub ubuntu-gcc-release (r-release)
- R-hub fedora-clang-devel (r-devel)

## R CMD check results

0 errors | 0 warnings | 0 note

## Release summary

* Fix invalid URL in README.

* Fix error caused by a namespace issue

* Change the behavior of geoparser_key() such that if no key is provided and
no key is saved in .Renviron either, the function errors with an informative 
error message (#11).
