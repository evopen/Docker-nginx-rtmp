FROM alpine:latest as builder

ARG NGINX_VERSION=1.21.1
ARG NGINX_RTMP_VERSION=1.2.2


RUN	apk update		&&	\
	apk add				\
		git			\
		gcc			\
		binutils		\
		gmp			\
		isl			\
		libgomp			\
		libatomic		\
		libgcc			\
		openssl			\
		pkgconf			\
		pkgconfig		\
		mpc1			\
		libstdc++		\
		ca-certificates		\
		libssh2			\
		curl			\
		expat			\
		pcre			\
		musl-dev		\
		libc-dev		\
		pcre-dev		\
		zlib-dev		\
		openssl-dev		\
		curl			\
		make


RUN	cd /tmp/									&&	\
	curl --remote-name http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz			&&	\
	git clone https://github.com/arut/nginx-rtmp-module.git -b v${NGINX_RTMP_VERSION}

RUN	cd /tmp										&&	\
	tar xzf nginx-${NGINX_VERSION}.tar.gz						&&	\
	cd nginx-${NGINX_VERSION}							&&	\
	./configure										\
		--prefix=/opt/nginx								\
		--with-http_ssl_module								\
		--add-module=../nginx-rtmp-module					&&	\
	make										&&	\
	make install

FROM rust:1.65.0-alpine
RUN apk add musl-dev
RUN cargo install --git https://github.com/evopen/hls-fragment-cleaner --tag 0.1.0 --target x86_64-unknown-linux-musl

FROM alpine:latest
LABEL org.opencontainers.image.authors="jason@jasonrivers.co.uk"
RUN apk update		&& \
	apk add			   \
		openssl		   \
		libstdc++	   \
		ca-certificates	   \
		pcre

COPY --from=0 /opt/nginx /opt/nginx
COPY --from=0 /tmp/nginx-rtmp-module/stat.xsl /opt/nginx/conf/stat.xsl
COPY --from=1 /usr/local/cargo/bin/hls-fragment-cleaner /usr/local/bin/hls-fragment-cleaner
RUN rm /opt/nginx/conf/nginx.conf
ADD run.sh /

EXPOSE 1935
EXPOSE 8080

CMD /run.sh

