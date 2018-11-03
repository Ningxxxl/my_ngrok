# my_ngrok
## 基础环境

> Server: Ubuntu 18.04 LTS 
>
> Local: macOS 10.13.6 
>
> Nginx: 1.14
>
> Docker: 18.10
>
> Image: hteen/ngrok



## 服务器端

### 拉取镜像

```shell
docker pull hteen/ngrok
```



### 生成ngrok客户端、服务器端和CA证书

启动的这个容器仅仅只是为了生成客户端、服务器端和证书。生成完毕之后会退出。

**`/home/ubuntu/docker/ngrok`这是宿主机的目录，生成的内容会存在于其中**。

如果`/bin/sh`报错，可以尝试`/bin/bash`

记得**替换`DOMAIN`参数**


```shell
docker run -it --rm \
-e DOMAIN="tunnel.ningxy.cn" \ 
-v /home/ubuntu/docker/ngrok:/myfiles \
hteen/ngrok /bin/sh /build.sh

./ngrok -config ./ngrok.cfg -subdomain wechat 127.0.0.1:8082
```

注：`--rm`可以使得容易退出后能够自动清理容器内部的文件系统。



指定目录下会产生一个`/bin`文件夹。结构如下：

```shell
bin/
├── darwin_amd64    macOS
│   └── ngrok
├── go-bindata
├── ngrok           Linux
├── ngrokd          Server
└── windows_amd64   Windows
    └── ngrok.exe

2 directories, 5 files
```

下载对应的客户端到自己电脑里。

例如macOS用户就下载`/darwin_amd64/ngrok`这个程序。保留好。



### 启动ngrok Server

创建容器运行server

记得**替换`DOMAIN`参数**

同时**保持目录的正确性**

至于宿主机端口映射可以自行更改

```shell
docker run -idt --name ngrok-server \
-v /home/ubuntu/docker/ngrok:/myfiles \
-p 10080:80 -p 10443:443 -p 14443:4443 \
-e DOMAIN='tunnel.ningxy.cn' \
hteen/ngrok /bin/sh /server.sh
```



### 配置Nginx

显然我并没有使用容器默认的80/443端口。

而域名A解析只能解析到IP。那么就需要一个Nginx来进行端口转发+反向代理。

* 安装Nginx

  ```shell
  sudo apt-get install nginx
  ```

* 配置

  打开配置文件

  ```shell
  vim /etc/nginx/nginx.conf
  ```

  加入：

  ```nginx
  server {
          listen       80;
          server_name  tunnel.ningxy.cn *.tunnel.ningxy.cn;
          location / {
                  proxy_redirect off;
                  proxy_set_header Host $host;
                  proxy_set_header X-Real-IP $remote_addr;
                  proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                  proxy_pass http://127.0.0.1:10080;
          }
  }
  
  server {
          listen       443;
          server_name  tunnel.ningxy.cn *.tunnel.ningxy.cn;
          location / {
                  proxy_redirect off;
                  proxy_set_header Host $host;
                  proxy_set_header X-Real-IP $remote_addr;
                  proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                  proxy_pass http://127.0.0.1:10443;
          }
  }
  ```

  键入命令使配置生效：

  ```shell
  nginx -s reload
  ```



## 域名解析

去域名提供商添加2条A解析：

主机记录：看自己喜欢什么域名，随意填，当然需要跟上面的`DOMAIN`一致

记录值：填写服务器IP，如果是内地服务器，记得备案。

| 记录类型 | 主机记录 |   记录值    |
| :------: | :------: | :---------: |
|    A     |  tunnel  | {Server_IP} |
|    A     | *.tunnel | {Server_IP} |



## 客户端（macOS）

我写了个小脚本，方便之后的快速运行：

打开终端，进入到合适的目录（随意定，能记住就行）

```shell
git clone https://github.com/Ningxxxl/my_ngrok.git && cd my_ngrok 
```

拷贝之前下载好的客户端程序`ngrok`到这个文件夹中。

此时目录结构应为：

```shell
/my_ngrok
├── README.md
├── ngrok       macOS客户端程序(从服务器生成下载得到)
├── ngrok.cfg   配置文件
└── start.sh    快速运行脚本

0 directories, 4 files
```

打开`ngrok.cfg`文件

修改`server_addr`属性对应的值为自己设置的域名和对应端口（容器4443对外映射的端口）

```shell
server_addr: "tunnel.ningxy.cn:4443"
trust_host_root_certs: false
```

保存，退出。



## 连接

给脚本执行权限：

```shell
chmod 777 ./start.sh
```

开始连接：

```shell
./start.sh
```

输入一个子域名（随意定）和映射的本地端口（也是随意）

输入完成后，提示：

```shell
Tunnel Status                 online
```

即完成。