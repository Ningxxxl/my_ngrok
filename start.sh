#!/bin/bash
function parse_yaml() {
    local yaml_file=$1
    local prefix=$2
    local s
    local w
    local fs
    s='[[:space:]]*'
    w='[a-zA-Z0-9_.-]*'
    fs="$(echo @|tr @ '\034')"
    (
        sed -ne '/^--/s|--||g; s|\"|\\\"|g; s/\s*$//g;' \
            -e "/#.*[\"\']/!s| #.*||g; /^#/s|#.*||g;" \
            -e  "s|^\($s\)\($w\)$s:$s\"\(.*\)\"$s\$|\1$fs\2$fs\3|p" \
            -e "s|^\($s\)\($w\)$s[:-]$s\(.*\)$s\$|\1$fs\2$fs\3|p" |
        awk -F"$fs" '{
            indent = length($1)/2;
            if (length($2) == 0) { conj[indent]="+";} else {conj[indent]="";}
            vname[indent] = $2;
            for (i in vname) {if (i > indent) {delete vname[i]}}
                if (length($3) > 0) {
                    vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
                    printf("%s%s%s%s=(\"%s\")\n", "'"$prefix"'",vn, $2, conj[indent-1],$3);
                }
            }' |
        sed -e 's/_=/+=/g' \
            -e '/\..*=/s|\.|_|' \
            -e '/\-.*=/s|\-|_|'
    ) < "$yaml_file"
}

function create_variables() {
    local yaml_file="$1"
    eval "$(parse_yaml "$yaml_file")"
}

function flashDarkBlue() {
    echo -n -e "\033[36m\033[01m\033[05m$1\033[0m"
}

function deleteLine() {
    echo -n -e "\033[1A\033[K\033[0m"
    if [ ! "$1" = "" ]; then
        echo $1
    fi
}

function getdomain() {
    create_variables "./ngrok.cfg"
    domain=${server_addr%:*}
    echo ${domain#*\"}
}

# 默认子域名
default_prefix="wechat"
# 默认本地端口
default_port=80
# 域名(从同级目录ngrok.cfg中获取)
domain=$(getdomain)

# 设置子域名
read -p "Enter prefix: (e.g. "$(flashDarkBlue ${default_prefix})".${domain}) " prefix
prefix=${prefix:-$default_prefix}
deleteLine "Set prefix compelete."

# 设置端口
read -p "Enter port: (e.g. "${prefix}"."${domain}":"$(flashDarkBlue ${default_port})") " port
port=${port:-$default_port}
deleteLine "Set port compelete."

# 启动服务
./ngrok -config ./ngrok.cfg -subdomain ${prefix} 127.0.0.1:${port}
