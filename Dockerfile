FROM alpine:3.5

MAINTAINER Shane.Cheng ccniubi@163.com ( http://github.com/kairyou/ )

ENV TOMCAT_VERSION 8.0.49
ENV LD_LIBRARY_PATH "/usr/local/apr/lib"
ENV TOMCAT_PACKAGE_URL "http://mirrors.hust.edu.cn/apache/tomcat/tomcat-8/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz"



# Modify respository and localtime of alpine
RUN  sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories && \ 
     apk update && \
     apk add tzdata && \
     ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
     echo "Asia/Shanghai" > /etc/timezone


RUN addgroup -S www \
	&& adduser -D -S -h /var/cache/www -s /sbin/nologin -G www www \
	&& apk add --no-cache --virtual .build-pro \
		openjdk8 gcc libc-dev make gd-dev apr-dev openssl-dev
		
RUN mkdir -p /usr/src && cd /usr/src \
  && wget -c $TOMCAT_PACKAGE_URL -O tomcat.tar.gz \
  && tar -zxf tomcat.tar.gz  \
  && mv /usr/src/apache-tomcat-$TOMCAT_VERSION /usr/local/tomcat \
  && rm -rf /usr/src \
  && rm -rf /usr/local/tomcat/webapps/* \
  && mv /usr/local/tomcat/conf/server.xml /usr/local/tomcat/conf/server.xml-bak \
  && mkdir -p /usr/local/tomcat/conf/vhost \
  && mkdir /website \
  && cd /usr/local/tomcat/bin && tar zxf tomcat-native.tar.gz \
  && cd /usr/local/tomcat/bin/tomcat-native-*src/native \
  && ./configure --with-java-home=/usr/lib/jvm/java-1.8-openjdk  --with-apr=/usr/bin \
  && make -j && make install \
  && cd /usr/local/tomcat && rm -rf LICENSE NOTICE RELEASE-NOTES RUNNING.txt \
  && rm -rf /usr/local/tomcat/bin/tomcat-native-*src/


COPY server.xml /usr/local/tomcat/conf/server.xml
COPY localhost.xml /usr/local/tomcat/conf/vhost/localhost.xml
COPY setenv.sh /usr/local/tomcat/bin/setenv.sh
COPY index.html /website/index.html

RUN chmod 755 /usr/local/tomcat/bin/setenv.sh \
  && ln -sf /dev/stdout /usr/local/tomcat/logs/catalina.out 


#VOLUME ["/usr/local/tomcat/logs","/website"]

EXPOSE 8080 8443

CMD ["/usr/local/tomcat/bin/catalina.sh","run"]

