#!/bin/bash

appName=Shopping_Cart //假设这个java服务叫购物车

cd /zuoyang/go-oomdump/

./build.sh

java -Xmx64m -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=./dump-jjops-$appName-$(date "+%Y.%m.%d-%H.%M.%S").hprof -XX:OnOutOfMemoryError=./go-oomdump -XX:+PrintGCDetails -XX:+PrintGCTimeStamps -XX:+PrintGCDateStamps -Xloggc:./gc.log -XX:+UseG1GC -Xloggc:gc-jjops-$appName-$(date "+%Y.%m.%d-%H.%M.%S").log -jar target/oom-example-1.0-SNAPSHOT.jar
