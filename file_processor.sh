#!/bin/bash

function processor() {
  countries=( $(ogrinfo source_data/ne_10m_admin_1_states_provinces_lakes.shp -sql "SELECT DISTINCT adm0_a3 FROM ne_10m_admin_1_states_provinces_lakes" -q -geom=NO | grep -o '\<[A-Z][A-Z][A-Z]\>') )

  country_errors=();
  for country in "${countries[@]}";
  do
    echo "$country"
    test -d "$country" && continue;
    country_error="$country"
    ogr2ogr -f GeoJSON -where "adm0_a3 = \"$country\"" states.json source_data/ne_10m_admin_1_states_provinces_lakes.shp && \
    mapshaper states.json -simplify 30% -o && \
    rm states.json && \
    mv states-ms.json states.json && \
    topojson --id-property adm1_cod_1 -p name=NAME -p name -o states.topo.json states.json && \
    mkdir $country && \
    mv states.topo.json "$country"/states.topo.json && \
    country_error=
    rm states.json
    if [ -n "$country_error" ]; then
      echo "error on $country_error"
      country_errors+=("$country_error")
      continue;
    fi
    oldifs=$IFS && IFS=$'\n'
    states=( $(ogrinfo source_data/ne_10m_admin_1_states_provinces_lakes.shp -q -sql "SELECT adm1_cod_1, name FROM ne_10m_admin_1_states_provinces_lakes WHERE adm0_a3 = \"$country\" GROUP BY adm1_cod_1" -dialect SQLITE -geom=NO -q | sed 's/OGRFeature.*//p' | sed 's/Layer name.*//p' | grep . | sed 'N;s/\n//g' | sed -En 's/  adm1_cod_1 \(String\) = (.*)  name \(String\) = (.*)/\1\n\2/p') )
    IFS=$oldifs
    state_errors=()
    for (( i=0; i < "${#states[@]}"; i+=2 )); do
      state_id="${states[i]}"
      state_name="${states[i+1]}"
      state_error="$state_id"
      ogr2ogr -f GeoJSON -where "ADM0_A3 = \"$country\" AND ADM1NAME = \"$state_name\"" cities.json source_data/ne_10m_populated_places.shp && \
      topojson -p name=NAME -p state=ADM1NAME -o cities.topo.json cities.json && \
      mv cities.topo.json "$country"/"$state_id"_cities.topo.json && \
      state_error=;
      rm cities.json
      if [ -n "$state_error" ]; then
        state_errors+=("$state_error")
        continue;
      fi
    done

    if [ ${#state_errors[@]} -gt 0 ]; then
     echo "$country state-level errors:"
     echo "${state_errors[@]}"
    fi
  done
  echo "${country_errors[@]}"
}

processor