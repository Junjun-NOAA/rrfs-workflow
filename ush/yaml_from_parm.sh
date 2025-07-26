#!/usr/bin/env bash
# generate the JEDI yaml files using templates from the parm/ directory
#
# shellcheck disable=SC2154
if [[ "$1" == "jedivar" ]]; then
  sed -e "s/@analysisDate@/${analysisDate}/" -e "s/@beginDate@/${beginDate}/" \
      -e "s/@HYB_WGT_STATIC@/${HYB_WGT_STATIC}/" -e "s/@HYB_WGT_ENS@/${HYB_WGT_ENS}/" \
      -e "s/@MPI_X@/${MPI_X}/" -e "s/@MPI_Y@/${MPI_Y}/" \
      -e "s/@NLAT@/${NLAT}/" -e "s/@NLON@/${NLON}/" \
      -e "s/@LAT_START@/${LAT_START}/" -e "s/@LAT_END@/${LAT_END}/" \
      -e "s/@LON_START@/${LON_START}/" -e "s/@LON_END@/${LON_END}/" \
      -e "s/@NORTH_POLE_LAT@/${NORTH_POLE_LAT}/" -e "s/@NORTH_POLE_LON@/${NORTH_POLE_LON}/" \
      "${EXPDIR}/config/jedivar.yaml" > jedivar.yaml
  if [[ "${HYB_WGT_ENS}" == "0" ]] || [[ "${HYB_WGT_ENS}" == "0.0" ]]; then # pure 3DVAR
    sed -i '123,148d' ./jedivar.yaml
  elif [[ "${HYB_WGT_STATIC}" == "0" ]] || [[ "${HYB_WGT_STATIC}" == "0.0" ]] ; then # pure 3DEnVar
    sed -i '78,122d' ./jedivar.yaml
  fi
  if [[ "${start_type}" == "cold" ]]; then
      sed -i '7s/mpasin/ana/' jedivar.yaml
  fi
  template="jedivar.yaml"

else
  TYPE_SED=${TYPE}
  # Use solver yaml for posterior observer (with a few changes)
  if [[ ${TYPE} == "post" ]]; then
      TYPE_SED="solver"
  fi
  sed -e "s/@analysisDate@/${analysisDate}/" -e "s/@beginDate@/${beginDate}/" \
    "${EXPDIR}/config/getkf_${TYPE_SED}.yaml" > getkf.yaml
  if [[ ${start_type} == "cold" ]]; then
      sed -i '43s/ens/ana/' getkf.yaml
  fi
  template="getkf.yaml"
fi

#
#  Generate the final YAML configuration file based on convinfo and available ioda files
#
"${cpreq}" "${EXPDIR}/config/convinfo" .
if [[ -s "${EXPDIR}/config/satinfo" ]]; then
  cp "${EXPDIR}/config/satinfo" .
fi
"${USHrrfs}/yaml_finalize" "${template}"
