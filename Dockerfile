FROM registry.cn-hangzhou.aliyuncs.com/mw5uk4snmsc/openjdk:8u212-jdk-alpine as builder

# 修改时区以及安装语言包
RUN apk add --no-cache tzdata && \
    echo "Asia/Shanghai" > /etc/timezone && \
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    apk del tzdata && \
    rm -rf /var/cache/apk/*

WORKDIR /opt

copy . .

RUN mkdir -pv /usr/local/go/release/ && \
    cd /usr/local/go/release/ && \
    wget https://golang.google.cn/dl/go1.21.5.linux-amd64.tar.gz && \
    tar -zxf go1.21.5.linux-amd64.tar.gz && \
    cd /usr/local/go/ && \
    ln -svf release/go current && \
    rm -rf /usr/local/go/release/go1.21.5.linux-amd64.tar.gz && \
    mv /opt/go.sh /etc/profile.d/ && \
    source /etc/profile && \
    go version && \
    cd /opt/go-oomdump-proj && \
    sh build.sh && \
    cp -rf go-oomdump /opt/ && \
    cd /opt


ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    JAVA_OPTS="-Xmx64m -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=./dump-jjops.hprof -XX:OnOutOfMemoryError=./go-oomdump -XX:+PrintGCDetails -XX:+PrintGCTimeStamps -XX:+PrintGCDateStamps -Xloggc:./gc.log -XX:+UseG1GC -Xloggc:gc-jjops.log"

#创建用户组和用户名
#RUN addgroup app && \
#    adduser -s -k -D -G app app

EXPOSE 8080

USER root

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar ./oom-example-1.0-SNAPSHOT.jar"]