#!/bin/bash

######################################################
# $Name:        upgrade.sh
# $Version:     v0.1
# $Function:    upgrade incremental sql files
# $Author:      gouhuan
# $Create Date: 2023-01-09
# $Description: shell
######################################################

set -e

## Variable
declare -A sqlFileMap
declare -a addSqlArry
declare -i index=0
scriptPath=$(cd $(dirname $0) && pwd -P)


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

Usage(){
 cat <<EOF
Execute incremental sql files within the version range.
Excluding the sql files of the currently deployed version.

usage: ${0} [OPTIONS]

The following flags are required.

    --path        Incremental sql path default is '/addsql/'.
    --nversion    New version.
    --oversion    Old version.
    --host        Mysql host ip default is 127.0.0.1.
    --user        Mysql user default is root.
    --password    Mysql password.
    --port        Mysql port default is 3306.
    --db          Mysql databases default is dtagent.
EOF
    exit 1
}


while [[ $# -gt 0 ]];do
    case ${1} in
        --path)
            path="$2"
            shift
            ;;
        --nversion)
            nversion="$2"
            shift
            ;;
        --oversion)
            oversion="$2"
            shift
            ;;
        --host)
            host="$2"
            shift
            ;;
        --user)
            user="$2"
            shift
            ;;
        --password)
            password="$2"
            shift
            ;;
        --port)
            port="$2"
            shift
            ;;
        --db)
            db="$2"
            shift
            ;;
        *)
            Usage
            ;;
    esac
    shift
done


[ -z ${path} ] && path="/addsql/"
[ -z ${nversion} ] && error "nversion variable is null"
[ -z ${oversion} ] && error "oversion variable is null"
[ -z ${host} ] && host=127.0.0.1
[ -z ${user} ] && user="root"
[ -z ${password} ] && error "password variable is null"
[ -z ${port} ] && port=3306
[ -z ${db} ] && db="dtagent"

MYSQLEXEC="mysql -h${host} -u${user} -p${password} -P${port}"
oldVersionNumb=$(echo ${oversion}|awk -F . '{print $1$2$3}')
newVersionNumb=$(echo ${nversion}|awk -F . '{print $1$2$3}')

# checkConection Check mysql database connection
checkConection() {
    info "MYSQL Connection check................................."
	$MYSQLEXEC -e "show databases;"
	if [ $? = 0 ]; then
		info "Connection successful:${MYSQLEXEC}"
	else
		error "Connection fail:${MYSQLEXEC}"
	fi
}

# initSqlMap 
# build sql file version to map
# example 20221130_v4.6.0.sql -> 460:20221130_v4.6.0.sql
initSqlMap() {
    for files in $(ls ${path});do
      versions=$(echo ${files}|grep -Eo "([0-9]\.[0-9]+\.[0-9]+|[0-9]\.[0-9]+)")
      verNumb=$(echo ${versions}|awk -F . '{print $1$2$3}')
      sqlFileMap["${verNumb}"]=${files}
    done
}

# getIncrementalSql 
# Generate a list of versions where incremental sql needs to be executed
getIncrementalSql(){
    for k in ${!sqlFileMap[*]};do
      if [[ ${k} -gt ${oldVersionNumb} && ${k} -le ${newVersionNumb} ]];then
          addSqlArry[${index}]=${k}
          index+=1
      fi
    done
}

# bubbleSort 
# Bubble sort,which handles the order in which incremental sql is executed
bubbleSort(){
    length=${#addSqlArry[@]}
    if [ ${length} -ne 0 ];then
        for ((i=1;i<=${length}-1;i++));do
            for ((j=0;j<=${length}-1;j++));do
                first=${addSqlArry[$j]}
                k=$[${j} + 1]
                second=${addSqlArry[$k]}

                if [[ ${first} -gt ${second} ]];then
                    temp=${first}
                    addSqlArry[${j}]=${second}
                    addSqlArry[${k}]=${temp}
                fi
            done
        done

        info "Need to exec incremental sql version list: ${addSqlArry[@]}"
    else
        info "No incremental sql file exists,When upgrade ${oversion} to ${nversion}"
        exit 0
    fi
}

# execAddSql Exec incremental sql file
execAddSql(){
    for v in ${addSqlArry[@]};do
        sqlFile=${sqlFileMap["${v}"]}
        info "Start exec add sql file: $MYSQLEXEC -vvv --show-warnings  ${db} < ${path}${sqlFile}"

        $MYSQLEXEC -vvv --show-warnings  ${db} < ${path}${sqlFile}

        if [ $? -ne 0 ];then
           error "Exec failed: $MYSQLEXEC -vvv --show-warnings  ${db} < ${path}${sqlFile}"
        fi
    done
}

main(){
    checkConection
    initSqlMap
    getIncrementalSql
    bubbleSort
    execAddSql
}

main