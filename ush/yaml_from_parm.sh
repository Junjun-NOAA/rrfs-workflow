#!/usr/bin/env bash
# generate the JEDI yaml files using templates from the parm/ directory
#
# shellcheck disable=SC2154
if [[ "$1" == "jedivar" ]]; then
  sed -e "s/@analysisDate@/${analysisDate}/" -e "s/@beginDate@/${beginDate}/" \
      "${EXPDIR}/config/jedivar.yaml" > jedivar.yaml

  if [[ "${STATIC_BEC_MODEL}" == "GSIBEC" ]]; then # GSIBEC 
    sed -i -e "s/@GSIBEC_X@/${GSIBEC_X}/" -e "s/@GSIBEC_Y@/${GSIBEC_Y}/" \
      -e "s/@GSIBEC_NLAT@/${GSIBEC_NLAT}/" -e "s/@GSIBEC_NLON@/${GSIBEC_NLON}/" \
      -e "s/@GSIBEC_LAT_START@/${GSIBEC_LAT_START}/" -e "s/@GSIBEC_LAT_END@/${GSIBEC_LAT_END}/" \
      -e "s/@GSIBEC_LON_START@/${GSIBEC_LON_START}/" -e "s/@GSIBEC_LON_END@/${GSIBEC_LON_END}/" \
      -e "s/@GSIBEC_NORTH_POLE_LAT@/${GSIBEC_NORTH_POLE_LAT}/" -e "s/@GSIBEC_NORTH_POLE_LON@/${GSIBEC_NORTH_POLE_LON}/" \
      jedivar.yaml
  elif [[ "${STATIC_BEC_MODEL}" == "BUMPBEC" ]]; then # BUMP BEC
    sed -i '/saber central block:/,/output variables: *incvars/ {
    r bumpbec.yaml
    d
    }' jedivar.yaml 
  fi

  if [[ "${HYB_WGT_ENS}" == "0" ]] || [[ "${HYB_WGT_ENS}" == "0.0" ]]; then # pure 3DVAR
    sed -i '/- covariance:/{N;/covariance model: ensemble/{:a;N;/HYB_WGT_ENS/!ba;d}}' jedivar.yaml
  elif [[ "${HYB_WGT_STATIC}" == "0" ]] || [[ "${HYB_WGT_STATIC}" == "0.0" ]] ; then # pure 3DEnVar
    sed -i '/- covariance:/{N;/covariance model: SABER/{:a;N;/HYB_WGT_STATIC/!ba;d}}' jedivar.yaml
  fi
  sed -i -e "s/@HYB_WGT_STATIC@/${HYB_WGT_STATIC}/" -e "s/@HYB_WGT_ENS@/${HYB_WGT_ENS}/" jedivar.yaml
  if [[ "${start_type}" == "cold" ]]; then
      sed -i '/output:/,/stream name:/{s/mpasout/ana/}' jedivar.yaml
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
     sed -i '/output:/,/stream name:/{s/ens/ana/}' getkf.yaml
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
