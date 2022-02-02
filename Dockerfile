ARG BASEIMAGE_BRANCH

FROM alpine:3.12 as builder

# Install build tools
RUN apk update && \
	apk --no-cache add \
		linux-headers \
		ca-certificates \
		make \
		file \
		automake \
		autoconf \
		pkgconf \
		libtool \
		gcc \
		g++ \
		git \
		wget
# Build libmodbus library
RUN mkdir -p /build/libmodbus && \
	git clone https://github.com/stephane/libmodbus /build/libmodbus && \
	cd /build/libmodbus && \
	./autogen.sh && \
	./configure --prefix=/usr && \
	make && \
	make install && \
	cd / && \
# Build sdm120c comm app
	mkdir -p /build/SDM120C && \
	git clone https://github.com/gianfrdp/SDM120C /build/SDM120C && \
	make -s -C /build/SDM120C/ clean && \
	make -s -C /build/SDM120C/

#FROM edofede/nginx-php-fpm:$BASEIMAGE_BRANCH
FROM edofede/nginx-php-fpm:latest

COPY --from=builder \
	/build/SDM120C/sdm120c \
	/usr/local/bin/

COPY --from=builder \
	/usr/lib/libmodbus.la \
	/usr/lib/libmodbus.so \
	/usr/lib/libmodbus.so.5 \
	/usr/lib/libmodbus.so.5.1.0 \
	/usr/lib/

# Install required software
RUN	apk update && \
	apk --no-cache add \
		rrdtool \
		jq \
		mosquitto-clients && \
	rm -rf /var/cache/apk/* && \
# Set local timezone
	cp /usr/share/zoneinfo/Europe/Rome /etc/localtime

COPY imageFiles/ /

# Setup base system and services
RUN sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php7/php.ini && \
	adduser nginx dialout && \
	adduser nginx uucp && \
	chmod 755 /var/www/scripts/updateMetern.sh && \
	chmod 4711 /usr/local/bin/sdm120c && \
# Download and install meterN
	/var/www/scripts/updateMetern.sh && \
# Set inizial account (Username: admin - Password:admin) for admin section
	printf "admin:$(openssl passwd -crypt admin)\\n" > /var/www/metern/config/.htpasswd && \
# Set permission and remove windows EOL chars
	chown -R nginx:www-data /var/www && \
	chmod 755 /var/www/metern/ /var/www/comapps/ && \
	sed -i -e 's/\r$//' /var/www/comapps/*  

ARG BUILD_DATE
ARG VERSION
ARG VCS_REF

LABEL 	maintainer="iomax" \
		org.label-schema.schema-version="0.0.0-rc.1" \
		org.label-schema.vendor="iomax" \
		org.label-schema.url="https://github.com/iomax/meterN-Docker/issues" \
		org.label-schema.name="metern" \
		org.label-schema.description="Docker multiarch image for meterN web apps" \
		org.label-schema.version=$VERSION \
		org.label-schema.build-date=$BUILD_DATE \
		org.label-schema.vcs-url="https://github.com/iomax/meterN-Docker" \
		org.label-schema.vcs-ref=$VCS_REF \
		org.label-schema.docker.cmd="SERVER_PORT=10080 && docker create --name meterN --device=/dev/ttyUSB0:rwm --volume metern_config:/var/www/metern/config --volume metern_data:/var/www/metern/data -p $SERVER_PORT:80 metern:latest"

VOLUME ["/var/www/metern/config", "/var/www/metern/data"]
