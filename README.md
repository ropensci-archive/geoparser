geoparser
=========

[![Build Status](https://travis-ci.org/ropenscilabs/geoparser.svg?branch=master)](https://travis-ci.org/ropenscilabs/geoparser) [![Build status](https://ci.appveyor.com/api/projects/status/7sw9ufcgh8pk1r5d?svg=true)](https://ci.appveyor.com/project/ropenscilabs/geoparser) [![codecov](https://codecov.io/gh/ropenscilabs/geoparser/branch/master/graph/badge.svg)](https://codecov.io/gh/ropenscilabs/geoparser)

This package is an interface to the [geoparser.io API](https://geoparser.io) that identifies places mentioned in text, disambiguates those places, and returns data about the places found in the text.

Installation
============

To install the package, you will need the devtools package.

``` r
library("devtools")
install_github("ropenscilabs/geoparser")
```

To get an API key, you need to register at <https://geoparser.io/pricing.html>. With an hobbyist account, you can make up to 1,000 calls a month to the API. Please note that the API is currently in beta and thus totally free! For ease of use, save your API key as an environment variable as described at <https://stat545-ubc.github.io/bit003_api-key-env-var.html>.

The package will conveniently look for your API key using `Sys.getenv("GEOPARSER_KEY")` so if your API key is an environment variable called "GEOPARSER\_KEY" you don't need to input it manually.

What is geoparsing?
===================

According to [Wikipedia](https://en.wikipedia.org/wiki/Geoparsing), geoparsing is the process of converting free-text descriptions of places (such as "Springfield") into unambiguous geographic identifiers (such as lat-lon coordinates). A geoparser is a tool that helps in this process. Geoparsing goes beyond geocoding in that, rather than analyzing structured location references like mailing addresses and numerical coordinates, geoparsing handles ambiguous place names in unstructured text.

Geoparser.io works best on complete sentences in *English*. If you have a very short text, such as a partial address like "`Auckland New Zealand`," you probably want to use a geocoder tool instead of a geoparser. In R, you can use the [opencage](https://cran.r-project.org/package=opencage) package for geocoding!

How to use the package
======================

You need to input a text whose size is less than 8KB.

``` r
library("geoparser")
output <- geoparser_q("I was born in Vannes and I live in Barcelona")
```

The output is list of 2 `data.frame`s (`dply::tbl_df`s). The first one is called `properties` and contains

-   the api version called `apiVersion`

-   the `source` of the results

-   the `id` of the query

-   `text_md5` is the MD5 hash of the text that was sent to the API.

``` r
output$properties
```

    ## # A tibble: 1 x 4
    ##   apiVersion       source                    id
    ## *     <fctr>       <fctr>                <fctr>
    ## 1      0.4.0 geoparser.io BDx1bAbcrXV3u5nObR5KV
    ## # ... with 1 more variables: text_md5 <chr>

The second data.frame contains the results and is called results:

``` r
knitr::kable(output$results)
```

| country | confidence | name      | admin1 | type                                           | geometry.type |  longitude|  latitude|  reference1|  reference2| text\_md5                        |
|:--------|:-----------|:----------|:-------|:-----------------------------------------------|:--------------|----------:|---------:|-----------:|-----------:|:---------------------------------|
| FR      | 1          | Vannes    | A2     | seat of a second-order administrative division | Point         |   -2.75000|  47.66667|          14|          20| 51e05aeb3366e55795a9729dd74ae901 |
| ES      | 1          | Barcelona | 56     | seat of a first-order administrative division  | Point         |    2.15899|  41.38879|          35|          44| 51e05aeb3366e55795a9729dd74ae901 |

-   `country` is the [ISO-3166 2-letter country code](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2) for the country in which this place is located, or NULL for features outside any sovereign territory.

-   `confidence` is a confidence score produced by the place name disambiguation algorithm. Currently returns a placeholder value; subject to change.

-   `name` is the best name for the specified location, with a preference for official/short name forms (e.g., "`New York`" over "`NYC`," and "`California`" over "`State of California`"), which may be different from exactly what appears in the text.

-   `admin1` is a code representing the state/province-level administrative division containing this place. (From GeoNames.org: *"Most adm1 are FIPS codes. ISO codes are used for US, CH, BE and ME. UK and Greece are using an additional level between country and fips code. The code '`00`' stands for general features where no specific adm1 code is defined."*).

-   `type` is a text description of the geographic feature type — see <GeoNames.org> for a complete list. Subject to change.

-   `geometry.type` is the type of the geographical feature, e.g. "`Point`".

-   `longitude` is the longitude.

-   `latitude` is the latitude.

-   `reference1` is the start (index of the first character in the place reference) -- each reference to this place name found in the input text is on one distinct line.

-   `reference2` the end (index of the first character after the place reference) -- each reference to the place name found in the input text is on one distinct line.

-   `text_md5` is the MD5 hash of the text that was sent to the API.

You can input a vector of characters since the function is vectorized. This is the case where the MD5 hash of each text can be useful for further analysis.

``` r
library("geoparser")
output_v <- geoparser_q(text_input = c("I was born in Vannes but I live in Barcelona.",
"France is the most beautiful place in the world.", "No place here."))
knitr::kable(output_v$results)
```

| country | confidence | name      | admin1 | type                                           | geometry.type |  longitude|  latitude|  reference1|  reference2| text\_md5                        |
|:--------|:-----------|:----------|:-------|:-----------------------------------------------|:--------------|----------:|---------:|-----------:|-----------:|:---------------------------------|
| FR      | 1          | Vannes    | A2     | seat of a second-order administrative division | Point         |   -2.75000|  47.66667|          14|          20| 90aba603d6b3f6b916c634f74ebc3a05 |
| ES      | 1          | Barcelona | 56     | seat of a first-order administrative division  | Point         |    2.15899|  41.38879|          35|          44| 90aba603d6b3f6b916c634f74ebc3a05 |
| FR      | 1          | France    | 00     | independent political entity                   | Point         |    2.00000|  46.00000|           0|           6| 33247ffc493ca57619549e512c7b5c59 |

``` r
knitr::kable(output_v$properties)
```

| apiVersion | source       | id                    | text\_md5                        |
|:-----------|:-------------|:----------------------|:---------------------------------|
| 0.4.0      | geoparser.io | AK4Xb8bh8Lr3TX6gDNxOB | 90aba603d6b3f6b916c634f74ebc3a05 |
| 0.4.0      | geoparser.io | JN5gwpwhVN2DcwY740WaQ | 33247ffc493ca57619549e512c7b5c59 |
| 0.4.0      | geoparser.io | p2OeVDVhrK1Jue0K1oldx | a9b35a32dc022502c943daa55520bfc0 |

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

| country | confidence | name   | admin1 | type                          | geometry.type |  longitude|  latitude|  reference1|  reference2| text\_md5                        |
|:--------|:-----------|:-------|:-------|:------------------------------|:--------------|----------:|---------:|-----------:|-----------:|:---------------------------------|
| FR      | 1          | France | 00     | independent political entity  | Point         |     2.0000|  46.00000|          51|          57| 34ac61cd71faef0cc4b336b706a7e545 |
| FR      | 1          | Paris  | A8     | capital of a political entity | Point         |     2.3488|  48.85341|           7|          12| 34ac61cd71faef0cc4b336b706a7e545 |
| FR      | 1          | Paris  | A8     | capital of a political entity | Point         |     2.3488|  48.85341|          17|          22| 34ac61cd71faef0cc4b336b706a7e545 |
| FR      | 1          | Paris  | A8     | capital of a political entity | Point         |     2.3488|  48.85341|          27|          32| 34ac61cd71faef0cc4b336b706a7e545 |

What happens if there are no results for the text?
==================================================

In this case the results table is empty.

``` r
output_nothing <- geoparser_q("No placename can be found.")
output_nothing$results
```

    ## # A tibble: 0 x 1
    ## # ... with 1 variables: text_md5 <chr>

How well does it work?
======================

The API team has tested the API un-scientifically and noticed a performance similar to other existing geoparsing tools. A scientific evaluation is under way. The public Geoparser.io API works best with professionally-written, professionally-edited news articles, but for Enterprise customers the API team says that it can be tuned/tweaked for other kinds of input (e.g., social media).

Let's look at this example:

``` r
output3 <- geoparser_q("I live in Hyderabad, India. My mother would prefer living in Hyderabad near Islamabad!")
knitr::kable(output3$results)
```

| country | confidence | name       | admin1 | type                                          | geometry.type |  longitude|  latitude|  reference1|  reference2| text\_md5                        |
|:--------|:-----------|:-----------|:-------|:----------------------------------------------|:--------------|----------:|---------:|-----------:|-----------:|:---------------------------------|
| IN      | 1          | Hyderabad  | 40     | seat of a first-order administrative division | Point         |   78.45636|  17.38405|          10|          19| 645d890dde2bce1092338f0cbc7af011 |
| IN      | 1          | Hyderabad  | 40     | seat of a first-order administrative division | Point         |   78.45636|  17.38405|          61|          70| 645d890dde2bce1092338f0cbc7af011 |
| IN      | 1          | India      | 00     | independent political entity                  | Point         |   79.00000|  22.00000|          21|          26| 645d890dde2bce1092338f0cbc7af011 |
| BD      | 1          | Chittagong | 84     | seat of a first-order administrative division | Point         |   91.83168|  22.33840|          76|          85| 645d890dde2bce1092338f0cbc7af011 |

Geoparser.io typically assumes two mentions of the same name appearing so closely together in the same input text refer to the same place. So, because it saw "`Hyderabad`" (India) in the first sentence, it assumes "`Hyderabad`" in the second sentence refers to the same city. Also, "`Islamabad`" is an alternate name for Chittagong, which has a higher population than Islamabad (Pakistan) and is closer to Hyderabad (India).

Here is another example with a longer text.

``` r
text <- "Aliwagwag is situated in the Eastern Mindanao Biodiversity \
Corridor which contains one of the largest remaining blocks of tropical lowland \
rainforest in the Philippines. It covers an area of 10,491.33 hectares (25,924.6 \
acres) and a buffer zone of 420.6 hectares (1,039 acres) in the hydrologically \
rich mountainous interior of the municipalities of Cateel and Boston in Davao \
Oriental as well as a portion of the municipality of Compostela in Compostela \
Valley. It is also home to the tallest trees in the Philippines, the Philippine \
rosewood, known locally as toog. In the waters of the upper Cateel River, a rare \
species of fish can be found called sawugnun by locals which is harvested as a \
delicacy." 

output4 <- geoparser_q(text)
knitr::kable(output4$results)
```

| country | confidence | name                       | admin1 | type                                 | geometry.type |  longitude|  latitude|  reference1|  reference2| text\_md5                        |
|:--------|:-----------|:---------------------------|:-------|:-------------------------------------|:--------------|----------:|---------:|-----------:|-----------:|:---------------------------------|
| PH      | 1          | Philippines                | 0      | independent political entity         | Point         |   122.0000|  13.00000|         159|         170| d89e347a998b58c6a8e54bc9f9abc073 |
| PH      | 1          | Philippines                | 0      | independent political entity         | Point         |   122.0000|  13.00000|         513|         524| d89e347a998b58c6a8e54bc9f9abc073 |
| PH      | 1          | Cateel                     | 11     | populated place                      | Point         |   126.4533|   7.79139|         354|         360| d89e347a998b58c6a8e54bc9f9abc073 |
| PH      | 1          | Boston                     | 11     | populated place                      | Point         |   126.3642|   7.87111|         365|         371| d89e347a998b58c6a8e54bc9f9abc073 |
| PH      | 1          | Province of Davao Oriental | 11     | second-order administrative division | Point         |   126.3333|   7.16667|         375|         390| d89e347a998b58c6a8e54bc9f9abc073 |
| PH      | 1          | Compostela Valley          |        | valley                               | Point         |   125.9586|   7.60755|         449|         467| d89e347a998b58c6a8e54bc9f9abc073 |
| PH      | 1          | Cateel River               | 11     | stream                               | Point         |   126.4533|   7.78750|         602|         614| d89e347a998b58c6a8e54bc9f9abc073 |

What can I do with the results?
===============================

You might want to map them using [leaflet](https://rstudio.github.io/leaflet/) or [ggmap](https://cran.r-project.org/web/packages/ggmap/index.html) or anything you like. The API website provides [suggestions of use](https://geoparser.io/uses.html) for inspiration.

Meta
----

-   Please [report any issues or bugs](https://github.com/ropenscilabs/geoparser/issues).
-   License: GPL
-   Get citation information for `geoparser` in R doing `citation(package = 'geoparser')`
-   Please note that this project is released with a [Contributor Code of Conduct](CONDUCT.md). By participating in this project you agree to abide by its terms.

[![ropensci\_footer](http://ropensci.org/public_images/github_footer.png)](http://ropensci.org)
