#!/bin/sh

# env var info
SCRIPT_PATH=$(cd $(dirname $0) && pwd -P)
DASH_DIR=${SCRIPT_PATH}/backup_dashboard
DASH_DB_FILE=${DASH_DIR}/das_db.json

SOURCE_GRAFANA_ENDPOINT="source_grafana_endpoint_here"
DEST_GRAFANA_ENDPOINT='dest_grafana_endpoint_here'

SOURCE_GRAFANA_API_KEY='source_grafana_api_key_here'
DEST_GRAFANA_API_KEY='dest_grafana_api_key_here'



log() {
    local type="$1"; shift
    # accept argument string or stdin
    local text="$*"; if [ "$#" -eq 0 ]; then text="$(cat)"; fi
    local dt; dt="$(date "+%Y-%m-%d %H:%M:%S")"
    printf '%s [%s] [upgrade.sh]: %s\n' "$dt" "$type" "$text"
}
info() {
    log INFO "$@"
}
warn() {
    log WARN "$@" >&2
}
error() {
    log ERROR "$@" >&2
    exit 1
}


if ! command -v curl &> /dev/null
then
    error "Please install curl before running this script"
fi

if ! command -v jq &> /dev/null
then
    error "Please install jq before running this script"
fi

function usage() {
    echo "Usage: ${0} -e -i" >&2
}

if [[ $# -eq 0 ]]; then
    usage
    exit 1
fi

while getopts "ei" opt; do
    case "${opt}" in
        e)
            export_dash="true"
            ;;
        i)
            import_dash="true"
            ;;
        *)
            usage
            exit 1
            ;;
    esac
done


if [[ "${export_dash}" == "true" ]]; then
    if [ ! -d "${DASH_DIR}" ]; then
        mkdir -p ${DASH_DIR}
    fi

    info "Downloading dash-db.........................."
    curl -sS -XGET \
         -H "Content-Type: application/json" \
         -H "Authorization: Bearer ${SOURCE_GRAFANA_API_KEY}" ${SOURCE_GRAFANA_ENDPOINT}/api/search?type="dash-db" > ${DASH_DB_FILE}
    [ $? -ne 0 ] && error "Failed: curl ${SOURCE_GRAFANA_ENDPOINT}/api/search?type="dash-db" > ${DASH_DB_FILE}"
    
    for uid in $(jq -r ".[].uid" ${DASH_DB_FILE}); do
      info "Downloading dashboard: ${uid}"
      curl -sS -XGET \
           -H "Authorization: Bearer ${SOURCE_GRAFANA_API_KEY}" ${SOURCE_GRAFANA_ENDPOINT}/api/dashboards/uid/${uid} > ${DASH_DIR}/uid.${uid}.json
      title=$(jq .dashboard.title ${DASH_DIR}/uid.${uid}.json | tr -d '"')
      cat ${DASH_DIR}/uid.${uid}.json|jq '.dashboard | del(.id)' > ${DASH_DIR}/dashboards.${title}.json
      info "Downloaded successed: ${title}-${uid}"
    done
fi

if [[ "${import_dash}" == "true" ]]; then
    if [ ! -d "${DASH_DIR}" ]; then
        error "${DASH_DIR} doesn't exist"
    fi

    if ! compgen -G "${DASH_DIR}/dashboards.*.json" > /dev/null; then
        error "No dashboards.*.json files in ${DASH_DIR}"
    fi

    for dashboard in $(ls ${DASH_DIR}/dashboards.*.json); do
        info "Uploading ${dashboard} to Grafana"
        dash_tmp=$(cat ${dashboard})
        dashJson='{"dashboard":'"${dash_tmp}}"

        curl -sS -XPOST -H "Content-Type: application/json" \
             -H "Authorization: Bearer ${DEST_GRAFANA_API_KEY}" \
             -d "${dashJson}" "${GRAFANA_ENDPOINT}/api/dashboards/db"
    
        echo -e "\n"
    done
fi