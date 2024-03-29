ARG COMP_VER=latest

FROM bowens/composer:${COMP_VER}
ARG YQ_VERSION=v4.35.2
ARG YQ_BINARY=yq_linux_amd64
RUN apk add --no-cache \
		ca-certificates \
		openssh-client

#RUN [ ! -e /etc/nsswitch.conf ] && echo 'hosts: files dns' > /etc/nsswitch.conf

ENV DOCKER_VERSION 23.0.6

WORKDIR /tmp

RUN set -eux; \
	\
	apk update; \
  apk upgrade; \
	rm -rf /app; \
	apk add --no-cache --virtual .build-deps \
    libzip-dev \
    zlib-dev \
		libpng-dev \
		freetype-dev \
		libjpeg-turbo-dev \
		sqlite \
		; \
    wget https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/${YQ_BINARY}.tar.gz -O - | \
      tar xz && mv ${YQ_BINARY} /usr/bin/yq \
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
			url="https://download.docker.com/linux/static/stable/x86_64/docker-$DOCKER_VERSION.tgz"; \
			;; \
		'armhf') \
			url="https://download.docker.com/linux/static/stable/armel/docker-$DOCKER_VERSION.tgz"; \
			;; \
		'armv7') \
			url="https://download.docker.com/linux/static/stable/armhf/docker-$DOCKER_VERSION.tgz"; \
			;; \
		'aarch64') \
			url="https://download.docker.com/linux/static/stable/aarch64/docker-$DOCKER_VERSION.tgz"; \
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
