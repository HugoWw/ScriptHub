# Usage:

### 1、exec_sql.sh脚本使用：
**用途: exec_sql.sh脚本是将指定目录下的所有sql文件导入到指定数据库中，若不指定目录则默认的目录是在/docker-entrypoint-initdb.d下**
`````
Execute full sql files to external databases.

usage: exec_sql.sh [OPTIONS]

The following flags are required.

    --path        Full sql file path default in mysql docker is '/docker-entrypoint-initdb.d'
    --host        Mysql host ip default is 127.0.0.1
    --user        Mysql user default is root
    --password    Mysql password
    --port        Mysql port default is 3306
`````

执行如下方式：
```
$ sh exec_all_sql.sh --host ${db_host} --user ${db_user} --password ${db_passwd} --port ${db_port} --path ${your_path}
```

### 2、upgrade_with_version.sh脚本使用：
**用途: upgrade_with_version.sh脚本是将指定目录下按照指定版本范围选择的sql文件，将其导入mysql数据库中，sql文件的命名规范中需要有版本信息，如: 
"20221130_v4.6.0.sql" 或 "app_name_v4.1.7.sql" 或 "v4.6.0_app_name.sql"**
`````
Execute incremental sql files within the version range.
Excluding the sql files of the currently deployed version.

usage: 1.sh [OPTIONS]

The following flags are required.

    --path        Incremental sql path default is '/addsql/'.
    --nversion    New version.
    --oversion    Old version.
    --host        Mysql host ip default is 127.0.0.1.
    --user        Mysql user default is root.
    --password    Mysql password.
    --port        Mysql port default is 3306.
    --db          Mysql databases default is dtagent.
`````

执行如下方式：
```
$ sh upgrade.sh --nversion 4.6.0 --oversion 4.1.7 --host ${db_host} --user ${db_user} --password ${db_passwd} --port ${db_port}
```
