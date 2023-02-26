# Usage:

## 一、Grafana：

### 1、dashboard_export_import.sh脚本使用：
使用的时候替换脚本中开头的相关变量：
````````
SOURCE_GRAFANA_ENDPOINT="源grafana的地址，如：http://127.0.0.1:3000"

DEST_GRAFANA_ENDPOINT="目标grafana的地址，如：http://127.0.0.1:3100" 

SOURCE_GRAFANA_API_KEY='访问源grafana的api密钥'

DEST_GRAFANA_API_KEY='访问目标grafana的api密钥'
````````
**若grafana都是通过匿名访问无效密钥，那么无需填写，脚本中删除引用密钥的变量即可**


导出仪表盘到 "DASH_DIR" 变量指定的目录下，执行如下方式导出：
```
$ sh dashboard_export_import.sh -e
```

导入仪表盘到目标grafana中，执行如下方式导入：
```
$ sh dashboard_export_import.sh -i
```
