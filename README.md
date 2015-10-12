# TopoJSON conversion for NaturalEarth ESRI Shape Files 

### Dependencies 
- [ogr2ogr](http://www.gdal.org/ogr2ogr.html)
- [geojson](http://geojson.org/)
- [topojson](https://github.com/mbostock/topojson)
- [mapshaper](https://github.com/mbloch/mapshaper)
- GNU sed

This is a little bash script that I used to convert country, state, and city data from [NaturalEarth](http://naturalearthdata.com) to topojson for use in a D3.js project. File structure will be `COUNTRYID1/states.topo.json`, `COUNTRYID1/STATEID1_cities.topo.json`, `COUNTRYID1/STATEID2_cities.topo.json`.

It covers the major bases and makes a good faith effort to catch errors, but there are still some issues that need to be worked out. Most notable is that if a location has an apostrophe in its name (Ivano-Frankivs'k, Va'a-o-Fonoti, Vava'u, etc) then it breaks the SQL query. This should be an easy fix, but it applies to a very small number of locations and I wanted to get this up on github. 

Feel free to use, change, and share as you see fit! 