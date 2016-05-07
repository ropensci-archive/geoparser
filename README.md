geoparser
=========

Installation
============

To install the package, you will need the devtools package.

``` r
library("devtools")
install_github("masalmon/geoparser")
```

This package is an interface to the [geoparser.io API](https://geoparser.io) that identifies places mentioned in text, disambiguates those places, and returns data about the places found in the text.

To get an API key, you need to register at <https://geoparser.io/pricing.html>. With an hobbyist account, you can make up to 1,000 calls a month to the API. For ease of use, save your API key as an environment variable as described at <https://stat545-ubc.github.io/bit003_api-key-env-var.html>.

The package will conveniently look for your API key using `Sys.getenv("GEOPARSER_KEY")` so if your API key is an environment variable called "GEOPARSER\_KEY" you don't need to input it manually.

Geoparsing
==========

You need to input a text whose size is less than 8kB.

The output is list of 2 data.frames (`dplyr tbl_df`). The first one is called and contains

-   the api version called `apiVersion`

-   the `source` of the results

-   the `id` of the query

The second data.frame contains the results and is called results:

-   `country` is the ISO-3166 2-letter country code for the country in which this place is located, or NULL for features outside any sovereign territory.

-   `confidence` is a confidence score produced by the place name disambiguation algorithm. Currently returns a placeholder value; subject to change.

-   `name` is the best name for the specified location, with a preference for official/short name forms (e.g., "New York" over "NYC," and "California" over "State of California"), which may be different from exactly what appears in the text.

-   `admin1` is a code representing the state/province-level administrative division containing this place. (From GeoNames.org: "Most adm1 are FIPS codes. ISO codes are used for US, CH, BE and ME. UK and Greece are using an additional level between country and fips code. The code '00' stands for general features where no specific adm1 code is defined.")

-   `type` is a text description of the geographic feature type — see GeoNames.org for a complete list. Subject to change.

-   `geometry.type` is the type of the geographical feature, e.g. "Point"

-   `geometry.coordinates1` is the longitude

-   `geometry.coordinates2` is the latitude

-   `reference1` is the start (index of the first character in the place reference) -- each reference to the this place name found in the input text is on one distinct line.

-   `reference2` the end (index of the first character after the place reference) -- each reference to the this place name found in the input text is on one distinct line.

``` r
library("geoparser")
output <- geoparser_q("I was born in Vannes and I live in Barcelona")
output$properties
```

    ## Source: local data frame [1 x 3]
    ## 
    ##   apiVersion       source                    id
    ##       (fctr)       (fctr)                (fctr)
    ## 1      0.3.4 geoparser.io yq2eRnRiKbLeTVddXlqGB

``` r
knitr::kable(output$results)
```

| type    | country | confidence | name      | admin1 | type                                           | id      | geometry.type |  geometry.coordinates1|  geometry.coordinates2|  number|  reference1|  reference2|
|:--------|:--------|:-----------|:----------|:-------|:-----------------------------------------------|:--------|:--------------|----------------------:|----------------------:|-------:|-----------:|-----------:|
| Feature | FR      | 1          | Vannes    | A2     | seat of a second-order administrative division | 2970777 | Point         |               -2.75000|               47.66667|       1|          14|          20|
| Feature | ES      | 1          | Barcelona | 56     | seat of a first-order administrative division  | 3128760 | Point         |                2.15899|               41.38879|       1|          35|          44|

If the input text contains several times the same placename, there is one line for each repetition, the each difference between lines being the values of `reference1` and `reference2`.

``` r
output2 <- geoparser_q("I like Paris and Paris and Paris and yeah it is in France!")
```

    ## No encoding supplied: defaulting to UTF-8.

    ## Warning in lapply(temp, as.numeric): NAs introduced by coercion

``` r
knitr::kable(output2$results)
```

| type    | country | confidence | name   | admin1 | type                          | id      | geometry.type |  geometry.coordinates1|  geometry.coordinates2|  number|  reference1|  reference2|
|:--------|:--------|:-----------|:-------|:-------|:------------------------------|:--------|:--------------|----------------------:|----------------------:|-------:|-----------:|-----------:|
| Feature | FR      | 1          | Paris  | A8     | capital of a political entity | 2988507 | Point         |                 2.3488|               48.85341|       1|           7|          12|
| Feature | FR      | 1          | Paris  | A8     | capital of a political entity | 2988507 | Point         |                 2.3488|               48.85341|       2|          17|          22|
| Feature | FR      | 1          | Paris  | A8     | capital of a political entity | 2988507 | Point         |                 2.3488|               48.85341|       3|          27|          32|
| Feature | FR      | 1          | France | 00     | independent political entity  | 3017382 | Point         |                 2.0000|               46.00000|       1|          51|          57|
