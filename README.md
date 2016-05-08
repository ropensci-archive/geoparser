geoparser
=========

[![Build Status](https://travis-ci.org/masalmon/geoparser.svg?branch=master)](https://travis-ci.org/masalmon/geoparser) [![Build status](https://ci.appveyor.com/api/projects/status/7sw9ufcgh8pk1r5d?svg=true)](https://ci.appveyor.com/project/masalmon/geoparser) [![codecov](https://codecov.io/gh/masalmon/geoparser/branch/master/graph/badge.svg)](https://codecov.io/gh/masalmon/geoparser)

Installation
============

To install the package, you will need the devtools package.

``` r
library("devtools")
install_github("masalmon/geoparser")
```

This package is an interface to the [geoparser.io API](https://geoparser.io) that identifies places mentioned in text, disambiguates those places, and returns data about the places found in the text.

To get an API key, you need to register at <https://geoparser.io/pricing.html>. With an hobbyist account, you can make up to 1,000 calls a month to the API. Please note that the API is currently in beta and thus totally free! For ease of use, save your API key as an environment variable as described at <https://stat545-ubc.github.io/bit003_api-key-env-var.html>.

The package will conveniently look for your API key using `Sys.getenv("GEOPARSER_KEY")` so if your API key is an environment variable called "GEOPARSER\_KEY" you don't need to input it manually.

What is geoparsing?
===================

According to [Wikipedia](https://en.wikipedia.org/wiki/Geoparsing), geoparsing is the process of converting free-text descriptions of places (such as "Springfield") into unambiguous geographic identifiers (such as lat-lon coordinates). A geoparser is a tool that helps in this process. Geoparsing goes beyond geocoding in that, rather than analyzing structured location references like mailing addresses and numerical coordinates, geoparsing handles ambiguous place names in unstructured text.

Geoparser.io works best on complete sentences in *English*. If you have a very short text, such as a partial address like "Auckland New Zealand," you probably want to use a geocoder tool instead of a geoparser. In R, you can use the [opencage](https://github.com/ropenscilabs/opencage) package for geocoding!

How to use the package?
=======================

You need to input a text whose size is less than 8kB.

``` r
library("geoparser")
output <- geoparser_q("I was born in Vannes and I live in Barcelona")
```

The output is list of 2 data.frames (`dplyr tbl_df`). The first one is called and contains

-   the api version called `apiVersion`

-   the `source` of the results

-   the `id` of the query

``` r
output$properties
```

    ## Source: local data frame [1 x 3]
    ## 
    ##   apiVersion       source                    id
    ##       (fctr)       (fctr)                (fctr)
    ## 1      0.3.4 geoparser.io YdZWlKlFGyJaudrrpLWNZ

``` r
knitr::kable(output$results)
```

| country | confidence | name      | admin1 | type                                           | geometry.type |  longitude|  latitude|  reference1|  reference2|
|:--------|:-----------|:----------|:-------|:-----------------------------------------------|:--------------|----------:|---------:|-----------:|-----------:|
| FR      | 1          | Vannes    | A2     | seat of a second-order administrative division | Point         |   -2.75000|  47.66667|          14|          20|
| ES      | 1          | Barcelona | 56     | seat of a first-order administrative division  | Point         |    2.15899|  41.38879|          35|          44|

The second data.frame contains the results and is called results:

-   `country` is the ISO-3166 2-letter country code for the country in which this place is located, or NULL for features outside any sovereign territory.

-   `confidence` is a confidence score produced by the place name disambiguation algorithm. Currently returns a placeholder value; subject to change.

-   `name` is the best name for the specified location, with a preference for official/short name forms (e.g., "New York" over "NYC," and "California" over "State of California"), which may be different from exactly what appears in the text.

-   `admin1` is a code representing the state/province-level administrative division containing this place. (From GeoNames.org: "Most adm1 are FIPS codes. ISO codes are used for US, CH, BE and ME. UK and Greece are using an additional level between country and fips code. The code '00' stands for general features where no specific adm1 code is defined.").

-   `type` is a text description of the geographic feature type — see GeoNames.org for a complete list. Subject to change.

-   `geometry.type` is the type of the geographical feature, e.g. "Point".

-   `longitude` is the longitude.

-   `latitude` is the latitude.

-   `reference1` is the start (index of the first character in the place reference) -- each reference to this place name found in the input text is on one distinct line.

-   `reference2` the end (index of the first character after the place reference) -- each reference to the place name found in the input text is on one distinct line.

``` r
knitr::kable(output$results)
```

| country | confidence | name      | admin1 | type                                           | geometry.type |  longitude|  latitude|  reference1|  reference2|
|:--------|:-----------|:----------|:-------|:-----------------------------------------------|:--------------|----------:|---------:|-----------:|-----------:|
| FR      | 1          | Vannes    | A2     | seat of a second-order administrative division | Point         |   -2.75000|  47.66667|          14|          20|
| ES      | 1          | Barcelona | 56     | seat of a first-order administrative division  | Point         |    2.15899|  41.38879|          35|          44|

How does it work?
=================

The API uses the Geonames.org gazetteer data. Geoparser.io uses a variety of named entity recognition tools to extract location names from the raw text input, and then applies a proprietary disambiguation algorithm to resolve location names to specific gazetteer records.

What happens if the same place occurs several times in the text?
================================================================

If the input text contains several times the same placename, there is one line for each repetition, the only difference between lines being the values of `reference1` and `reference2`.

``` r
output2 <- geoparser_q("I like Paris and Paris and Paris and yeah it is in France!")
knitr::kable(output2$results)
```

| country | confidence | name   | admin1 | type                          | geometry.type |  longitude|  latitude|  reference1|  reference2|
|:--------|:-----------|:-------|:-------|:------------------------------|:--------------|----------:|---------:|-----------:|-----------:|
| FR      | 1          | Paris  | A8     | capital of a political entity | Point         |     2.3488|  48.85341|           7|          12|
| FR      | 1          | Paris  | A8     | capital of a political entity | Point         |     2.3488|  48.85341|          17|          22|
| FR      | 1          | Paris  | A8     | capital of a political entity | Point         |     2.3488|  48.85341|          27|          32|
| FR      | 1          | France | 00     | independent political entity  | Point         |     2.0000|  46.00000|          51|          57|

How well does it work?
======================

Well ask the geoparser.io team, because I don't know! Please note that the API is currently in beta. I guess for now the best is to try things out!

Let's test the API with a difficult text.

``` r
output3 <- geoparser_q("I live in Hyderabad, India. My mother would prefer living in Hyderabad near Islamabad!")
knitr::kable(output3$results)
```

| country | confidence | name       | admin1 | type                                          | geometry.type |  longitude|  latitude|  reference1|  reference2|
|:--------|:-----------|:-----------|:-------|:----------------------------------------------|:--------------|----------:|---------:|-----------:|-----------:|
| IN      | 1          | Hyderabad  | 40     | seat of a first-order administrative division | Point         |   78.45636|  17.38405|          10|          19|
| IN      | 1          | Hyderabad  | 40     | seat of a first-order administrative division | Point         |   78.45636|  17.38405|          61|          70|
| IN      | 1          | India      | 00     | independent political entity                  | Point         |   79.00000|  22.00000|          21|          26|
| BD      | 1          | Chittagong | 84     | seat of a first-order administrative division | Point         |   91.83168|  22.33840|          76|          85|

Or a text with more info.

``` r
output4 <- geoparser_q("I live in Hyderabad, India. My mother would prefer living in Hyderabad, the city in Pakistan!")
knitr::kable(output4$results)
```

| country | confidence | name      | admin1 | type                                          | geometry.type |  longitude|  latitude|  reference1|  reference2|
|:--------|:-----------|:----------|:-------|:----------------------------------------------|:--------------|----------:|---------:|-----------:|-----------:|
| IN      | 1          | Hyderabad | 40     | seat of a first-order administrative division | Point         |   78.45636|  17.38405|          10|          19|
| IN      | 1          | Hyderabad | 40     | seat of a first-order administrative division | Point         |   78.45636|  17.38405|          61|          70|
| PK      | 1          | Pakistan  | 0      | independent political entity                  | Point         |   70.00000|  30.00000|          84|          92|
| IN      | 1          | India     | 00     | independent political entity                  | Point         |   79.00000|  22.00000|          21|          26|
