#!/bin/bash

# Вытащим логи из контейнера apiserver
minikube ssh -- "PID=\$(sudo crictl inspect \$(sudo crictl ps --name kube-apiserver -q | head -1) | grep -m1 '\"pid\"' | awk '{print \$2}' | tr -d ','); sudo cat /proc/\$PID/root/var/log/audit.log" > audit.log