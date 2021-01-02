ARG COMP_VER=latest

FROM composer:${COMP_VER}

RUN apk add --no-cache \
		ca-certificates \
		openssh-client

RUN [ ! -e /etc/nsswitch.conf ] && echo 'hosts: files dns' > /etc/nsswitch.conf

ENV DOCKER_VERSION 20.10.0-rc2

WORKDIR /tmp

RUN set -eux; \
	\
	rm -rf /app; \
	apk add --no-cache --virtual .build-deps \
    libzip-dev \
    zlib-dev \
		libpng-dev \
		freetype-dev \
		libjpeg-turbo-dev \
		sqlite \
		; \
	docker-php-ext-configure gd \
		--with-freetype \
		--with-jpeg=/usr/include \
		; \
	docker-php-ext-install -j "$(nproc)" \
		gd \
		zip \
		; \
	apkArch="$(apk --print-arch)"; \
	case "$apkArch" in \
		'x86_64') \
			url='https://download.docker.com/linux/static/test/x86_64/docker-20.10.0-rc2.tgz'; \
			;; \
		'armhf') \
			url='https://download.docker.com/linux/static/test/armel/docker-20.10.0-rc2.tgz'; \
			;; \
		'armv7') \
			url='https://download.docker.com/linux/static/test/armhf/docker-20.10.0-rc2.tgz'; \
			;; \
		'aarch64') \
			url='https://download.docker.com/linux/static/test/aarch64/docker-20.10.0-rc2.tgz'; \
			;; \
		*) echo >&2 "error: unsupported architecture ($apkArch)"; exit 1 ;; \
	esac; \
	\
	wget -O docker.tgz "$url"; \
	\
	tar --extract \
		--file docker.tgz \
		--strip-components 1 \
		--directory /usr/local/bin/ \
	; \
	rm docker.tgz; \
	\
	dockerd --version; \
	docker --version
