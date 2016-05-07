geoparser
=========

Installation
============

To install the package, you will need the devtools package.

``` r
library("devtools")
install_github("masalmon/geoparser")
```

This package is an interface to the [geoparser.io API](https://geoparser.io) that identifies places mentioned in text, disambiguates those places, and returns GeoJSON with detailed metadata about the places found in the text.

To get an API key, you need to register at . With an hobbyist account, you can make up to 1,000 calls a month to the API. For ease of use, save your API key as an environment variable as described at <https://stat545-ubc.github.io/bit003_api-key-env-var.html>.

The package will conveniently look for your API key using `Sys.getenv("GEOPARSER_KEY")` so if your API key is an environment variable called "GEOPARSER\_KEY" you don't need to input it manually.

Geoparsing
==========

``` r
library("geoparser")
output <- geoparser_q("I was born in Vannes and I live in Barcelona")
output$properties
```

    ##   apiVersion       source                    id
    ## 1      0.3.4 geoparser.io OjKApepu5Jajt05JZQ4AY

``` r
knitr::kable(output$results)
```

| properties.country | properties.references1 | properties.references2 | properties.confidence | properties.name | properties.admin1 | properties.type                                | id      | geometry.type |  geometry.coordinates1|  geometry.coordinates2|
|:-------------------|:-----------------------|:-----------------------|:----------------------|:----------------|:------------------|:-----------------------------------------------|:--------|:--------------|----------------------:|----------------------:|
| FR                 | 14                     | 20                     | 1                     | Vannes          | A2                | seat of a second-order administrative division | 2970777 | Point         |               -2.75000|               47.66667|
| ES                 | 35                     | 44                     | 1                     | Barcelona       | 56                | seat of a first-order administrative division  | 3128760 | Point         |                2.15899|               41.38879|
