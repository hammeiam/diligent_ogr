# TopoJSON conversion for NaturalEarth ESRI Shape Files 

### Dependencies 
- [ogr2ogr](http://www.gdal.org/ogr2ogr.html)
- [geojson](http://geojson.org/)
- [topojson](https://github.com/mbostock/topojson)
- [mapshaper](https://github.com/mbloch/mapshaper)
- GNU sed

This is a little bash script that I used to convert country, state, and city data from [NaturalEarth](http://naturalearthdata.com) to topojson for use in a D3.js project. File structure will be `COUNTRYID1/states.topo.json`, `COUNTRYID1/STATEID1_cities.topo.json`, `COUNTRYID1/STATEID2_cities.topo.json`.

Be sure to check out the annotated source if you're curious about how it works.

Feel free to use, change, and share as you see fit! 

Here's test text, delete me later!