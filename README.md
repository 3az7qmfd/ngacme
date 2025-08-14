# NGINX with ACME 模块 Docker 镜像

本仓库提供了一个 `Dockerfile`，用于构建一个包含官方 [nginx-acme](https://github.com/nginx/nginx-acme) 模块的多平台 NGINX 镜像（`linux/amd64`, `linux/arm64`）。该模块可通过 Let's Encrypt 及其他兼容 ACME 协议的 CA 实现 SSL 证书的自动管理。基于的镜像版本 `nginx:1.29.1`

## ✨ 特性

- **NGINX 集成 `ngx_http_acme_module`**: 实现证书的自动申请与续期。
- **多平台构建**: 同时支持 `linux/amd64` 和 `linux/arm64` 架构。

## 🚀 使用方法

镜像会自动发布到 `ghcr.io`。您可以使用以下命令拉取：

```sh
docker pull ghcr.io/3az7qmfd/ngacme:main
```

要运行容器，您可以通过如下配置文件：

```yml
# 示例:
services:
  nginx:
    # build:
    #   context: .
    #   dockerfile: Dockerfile
    image: ghcr.io/3az7qmfd/ngacme:main
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/conf:/etc/nginx/conf.d # nginx 配置
      - ./nginx/html:/usr/share/nginx/html # 站点文件
      - ./nginx/acme:/var/lib/nginx/acme # ACME证书持久化的存放目录
    restart: always
```

## 🔧 配置

`ngx_http_acme_module.so` 模块在镜像中已自动加载。您只需在 站点的 `conf` 中进行相应配置即可。以下是一个最小化配置示例，需要放到 当前 `nginx/conf.d` 目录下，或者采用你喜欢的方式挂载到 `/etc/nginx/conf.d` 下：

```nginx
resolver 1.1.1.1:53 ipv6=off;

acme_issuer example {
    uri         https://acme-v02.api.letsencrypt.org/directory;
    contact     admin@xxxx.com; # 改为自己的邮箱
    state_path  /var/lib/nginx/acme/example;
    accept_terms_of_service;
}
acme_shared_zone zone=ngx_acme_shared:1M;

server {
    listen 80;
    server_name  yourdomain.com; # 改为自己的域名

    location / {
        return 404;
    }
}
server {
    listen 443 ssl;
    http2 on;
    server_name  yourdomain.com; # 改为自己的域名

    acme_certificate example;
    ssl_certificate        $acme_certificate;
    ssl_certificate_key    $acme_certificate_key;
    ssl_certificate_cache max=2;

    location / {
        return 404;
    }
}
```

