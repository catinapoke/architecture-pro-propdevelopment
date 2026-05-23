#!/bin/bash

# Вытащим логи из контейнера apiserver
minikube ssh -- "PID=\$(sudo crictl inspect \$(sudo crictl ps --name kube-apiserver -q | head -1) | grep -m1 '\"pid\"' | awk '{print \$2}' | tr -d ','); sudo cat /proc/\$PID/root/var/log/audit.log" > audit.log

LOG="${1:-audit.log}"
OUT="audit-extract.json"

# Очищаем выжимку перед заполнением
> "$OUT"

# Доступ к secrets от monitoring SA
jq -c 'select(.impersonatedUser.username=="system:serviceaccount:secure-ops:monitoring"
              and .objectRef.resource=="secrets"
              and .stage=="ResponseComplete")' "$LOG" | tee -a "$OUT"

# Привилегированные поды
jq -c 'select(.objectRef.resource=="pods"
              and .verb=="create"
              and .stage=="ResponseComplete"
              and ((.requestObject.spec.containers[]?.securityContext.privileged // false) == true))' "$LOG" | tee -a "$OUT"

# kubectl exec в kube-system
jq -c 'select(.objectRef.subresource=="exec"
              and .objectRef.namespace=="kube-system"
              and .stage=="ResponseComplete")' "$LOG" | tee -a "$OUT"

# RoleBinding с правами cluster-admin
jq -c 'select((.objectRef.resource=="rolebindings" or .objectRef.resource=="clusterrolebindings")
              and .verb=="create"
              and .stage=="ResponseComplete"
              and (.requestObject.roleRef.name // "")=="cluster-admin")' "$LOG" | tee -a "$OUT"

# Удаление чего-либо от --as=admin
jq -c 'select(.impersonatedUser.username=="admin"
              and .verb=="delete"
              and .stage=="ResponseComplete")' "$LOG" | tee -a "$OUT"
