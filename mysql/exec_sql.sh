#!/bin/bash

######################################################
# $Name:        exec_all_sql.sh
# $Version:     v0.1
# $Function:    exec all sql files 
# $Author:      gouhuan
# $Create Date: 2023-01-10
# $Description: shell
######################################################


log() {
	local type="$1"; shift
	# accept argument string or stdin
	local text="$*"; if [ "$#" -eq 0 ]; then text="$(cat)"; fi
    local dt; dt="$(date "+%Y-%m-%d %H:%M:%S")"
	printf '%s [%s] [exec_all_sql.sh]: %s\n' "$dt" "$type" "$text"
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
Execute full sql files to external databases.

usage: ${0} [OPTIONS]

The following flags are required.

    --path        Full sql file path default in mysql docker is '/docker-entrypoint-initdb.d'
    --host        Mysql host ip default is 127.0.0.1
    --user        Mysql user default is root
    --password    Mysql password
    --port        Mysql port default is 3306
EOF
    exit 1
}


while [[ $# -gt 0 ]];do
    case ${1} in
        --path)
            path="$2"
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
        *)
            Usage
            ;;
    esac
    shift
done



[ -z ${path} ] && path="/docker-entrypoint-initdb.d"
[ -z ${host} ] && host=127.0.0.1
[ -z ${user} ] && user="root"
[ -z ${password} ] && error "password variable is null"
[ -z ${port} ] && port=3306

MYSQLEXEC="mysql -h${host} -u${user} -p${password} -P${port}"


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


# usage: process_init_files [file [file [...]]]
#    ie: process_init_files /always-initdb.d/*
# process initializer files, based on file extensions
process_init_files(){
    local f

    for f;do
        case "$f" in
            *.sql)
                info "$0: running $f"; process_sql < "$f"; echo ;;
        esac
    done
    

    
}

# Execute sql script, passed via stdin
# usage: process_sql <<<'INSERT ...'
#    ie: process_sql <my-file.sql
process_sql(){
    $MYSQLEXEC -vvv --show-warnings --comments "$@"
    if [ $? -ne 0 ];then
        error "Process Sql Input Failed: $MYSQLEXEC -vvv --show-warnings --comments "$@""
    fi
}


main(){
    checkConection
    process_init_files ${path}/*
}

main
