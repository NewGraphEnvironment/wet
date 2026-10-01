# Measured AET by land-cover class (Chapman et al. 2018, Table 3)

One value per class from Table 3 of Chapman et al. (2018, p. 8). Where
the table has a Canada-wide value (Liu et al. 2003) it is used, so all
classes come from one study where possible. The exceptions are wetland,
the midpoint of the subarctic boreal fen range (313-341 mm; Chapman
1988), and water, the midpoint of the NE British Columbia range (350-500
mm; Canada 1978). Each class carries the NRCan 2020 land-cover codes
that map to it.

## Usage

``` r
wet_chapman_table3()
```

## Value

`data.frame(class, aet_mm, table3_setting, table3_aet, reference, nrcan_2020_codes)`;
the codes are `;`-separated.

## Examples

``` r
wet_chapman_table3()[c("class", "aet_mm", "nrcan_2020_codes")]
#>         class aet_mm nrcan_2020_codes
#> 1  coniferous    276              1;2
#> 2   deciduous    492                5
#> 3       mixed    405                6
#> 4       shrub    195             8;11
#> 5       grass    275            10;12
#> 6      barren    126            13;16
#> 7     wetland    327               14
#> 8        crop    341               15
#> 9       urban    195               17
#> 10      water    425               18
#> 11   snow_ice     51               19
```
