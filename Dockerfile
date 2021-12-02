FROM alpine:3.14 AS builder

ARG S3FS_VERSION=1.90
ARG S3FS_RELEASE_TARGZ=https://github.com/s3fs-fuse/s3fs-fuse/archive/refs/tags/v${S3FS_VERSION}.tar.gz

RUN apk --update add fuse alpine-sdk automake autoconf libxml2-dev fuse-dev curl-dev git bash linux-pam-dev;

WORKDIR /opt
RUN wget "$S3FS_RELEASE_TARGZ" -O s3fs-fuse.tar.gz

RUN tar -xvzf s3fs-fuse.tar.gz

WORKDIR /opt/s3fs-fuse-${S3FS_VERSION}

RUN ./autogen.sh && \
    ./configure --prefix=/usr/local  && \
    make && \
    make install

COPY libpam-pwdfile.zip /opt/

RUN set -ex \
    && unzip -q /opt/libpam-pwdfile.zip -d /opt/ \
    && cd /opt/libpam-pwdfile \
    && make install

RUN ls -lh /usr/local/bin

RUN find / -name pam_pwdfile.so

RUN echo $PATH
RUN ls -lh /root
#RUN echo ${S3FS_RELEASE_TARGZ}

FROM alpine:3.14 AS base
MAINTAINER Andrey Tsarev

RUN apk --update add vsftpd fuse libxml2 curl libstdc++ apache2-utils openssl linux-pam

RUN addgroup -S vsftpd && adduser -S vsftpd -G vsftpd
WORKDIR /home/vsftpd

COPY --from=builder /usr/local/bin/s3fs /usr/local/bin/
COPY --from=builder /lib/security/pam_pwdfile.so /lib/security/pam_pwdfile.so

COPY docker-entrypoint.sh docker-entrypoint.sh
COPY vsftpd.conf /root/vsftpd.conf

# Copy pam file
COPY vsftpd /etc/pam.d/vsftpd
RUN chmod 644 /etc/pam.d/vsftpd

ENV BUCKET_FOLDER=/root/buckets

ENTRYPOINT ["sh", "docker-entrypoint.sh"]
CMD ["vsftpd", "/root/vsftpd.conf"]
