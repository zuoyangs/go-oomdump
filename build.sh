#!/bin/bash

source /etc/profile
set GOOS=linux
go build -ldflags "-w -s" -o go-oomdump main.go