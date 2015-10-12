#!/bin/bash

function processor() {
  # select unique country codes from the provided shapefile. 
  # this will output about 200 sets of lines that look like:
  #   OGRFeature(ne_10m_admin_1_states_provinces_lakes):240
  #   adm0_a3 (String) = USA
  # we use grep to isolate and return the country code (USA)
  # these results are then dumped into an array named 'countries'
  countries=( $(ogrinfo source_data/ne_10m_admin_1_states_provinces_lakes.shp -sql "SELECT DISTINCT adm0_a3 FROM ne_10m_admin_1_states_provinces_lakes" -q -geom=NO | grep -o '\<[A-Z][A-Z][A-Z]\>') )

  # initialize empty array to store any errors
  country_errors=();
  for country in "${countries[@]}";
  do
    echo "$country"
    # if we already have a folder for this country, 
    # we assume it's been processed and we can skip it
    test -d "$country" && continue;
    country_error="$country"
    # select the country from the shapefile, convert it to geojson
    ogr2ogr -f GeoJSON -where "gu_a3 = '$country'" states.json source_data/ne_10m_admin_1_states_provinces_lakes.shp && \
    # use mapshaper to simplify the geojson file to make it smaller for the web
    mapshaper states.json -simplify 30% -o && \
    # clean up files
    rm states.json && \
    mv states-ms.json states.json && \
    # convert geojson to topojson, perserve adm1_cod_1 and name
    topojson --id-property adm1_cod_1 -p name=NAME -p name -o states.topo.json states.json && \
    # create a folder for the country, add our states file to it
    mkdir $country && \
    mv states.topo.json "$country"/states.topo.json && \
    country_error=
    rm states.json
    # if any command in a chain separated by && fails, 
    # then nothing after it will run. By nullifying 'country_error'
    # at the end of the chain, we can easily check for failures
    # by seeing if country_error is null or not
    if [ -n "$country_error" ]; then
      echo "error on $country_error"
      country_errors+=("$country_error")
      continue;
    fi
    # $IFS stands for Internal Field Seprator and it tells bash which characters
    # should be used to split fields. It is usally set to spaces, but because
    # some of the values we will be processing will be one term separated by spaces
    # (like 'New York'), we need to tell bash to separate on something other than spaces.
    # Store the old value of IFS so we can reset it when we're done. Set to newline.
    oldifs=$IFS && IFS=$'\n'
    # Select the adm1_cod_1 and name for all states in the current $country.
    # The first 2 seds strip out unnecessary lines
    # grep strips out empty lines
    # The 3rd sed concatenates every 2 lines into 1 for easier processing
    # the 4th sed uses regex to capture the values we want and return them, 
    # separated by a newline so bash will make them separate elements in our array
    states=( $(ogrinfo source_data/ne_10m_admin_1_states_provinces_lakes.shp -q -sql "SELECT adm1_cod_1, name FROM ne_10m_admin_1_states_provinces_lakes WHERE adm0_a3 = '$country' GROUP BY adm1_cod_1" -dialect SQLITE -geom=NO -q | sed 's/OGRFeature.*//p' | sed 's/Layer name.*//p' | grep . | sed 'N;s/\n//g' | sed -En 's/  adm1_cod_1 \(String\) = (.*)  name \(String\) = (.*)/\1\n\2/p') )
    # reset IFS
    IFS=$oldifs
    # initialize state-level errors array
    state_errors=()
    # bash doesn't allow for multidimensional arrays, so we cheat and
    # iterate through every second item (0,2,4...) and treat (1,3,5) as its pair
    for (( i=0; i < "${#states[@]}"; i+=2 )); do
      state_id="${states[i]}"
      state_name="${states[i+1]}"
      state_error="$state_id"
      # select cities in the current country and state, save a geojson
      ogr2ogr -f GeoJSON -where "ADM0_A3 = '$country' AND ADM1NAME = '$state_name'" cities.json source_data/ne_10m_populated_places.shp && \
      # convert geojson to topojson, preserving name and state name
      topojson -p name=NAME -p state=ADM1NAME -o cities.topo.json cities.json && \
      # move and rename the file to follow our name scheme
      mv cities.topo.json "$country"/"$state_id"_cities.topo.json && \
      state_error=;
      rm cities.json
      # use the same trick as before to log errors in processing
      if [ -n "$state_error" ]; then
        state_errors+=("$state_error")
        continue;
      fi
    done
    # display errors
    if [ ${#state_errors[@]} -gt 0 ]; then
     echo "$country state-level errors:"
     echo "${state_errors[@]}"
    fi
  done
  echo "${country_errors[@]}"
}

processor