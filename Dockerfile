# ================================
# 阶段 1: 编译 ngx_http_acme_module.so
# ================================
FROM debian:bookworm-slim AS builder

ARG NGINX_VERSION=1.29.4

RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc make curl git perl \
    libpcre3-dev zlib1g-dev libssl-dev ca-certificates \
    pkg-config clang libclang-dev \
    && rm -rf /var/lib/apt/lists/*


# 安装 Rust
ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable

WORKDIR /build

# 下载 NGINX
RUN curl -fSL https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz | tar xz
WORKDIR /build/nginx-${NGINX_VERSION}

# 配置并构建 NGINX (仅供模块编译)
RUN ./configure --with-compat --with-http_ssl_module && make

# 下载 nginx-acme
WORKDIR /build
RUN git clone https://github.com/nginx/nginx-acme.git

# 使用 Cargo 构建（体积更小）
WORKDIR /build/nginx-acme
RUN export NGINX_BUILD_DIR=/build/nginx-${NGINX_VERSION}/objs \
    && cargo build --release

RUN mkdir -p /output/modules \
    && cp target/release/libnginx_acme.so /output/modules/ngx_http_acme_module.so

# ================================
# 阶段 2: 运行镜像
# ================================
FROM nginx:1.29.1

COPY --from=builder /output/modules/ngx_http_acme_module.so /usr/lib/nginx/modules/

# 创建 ACME 状态目录
RUN mkdir -p /var/lib/nginx/acme && chown -R nginx:nginx /var/lib/nginx/acme && sed -i '1iload_module modules/ngx_http_acme_module.so;' /etc/nginx/nginx.conf

# 单独的模块加载文件
#RUN echo "load_module modules/ngx_http_acme_module.so;" > /etc/nginx/conf.d/00-acme.conf

EXPOSE 80 443
CMD ["nginx", "-g", "daemon off;"]
