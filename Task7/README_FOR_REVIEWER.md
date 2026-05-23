# Задание 7. Аудит и обеспечение соответствия политике безопасности контейнеров (PSP / PodSecurity / OPA Gatekee

## Решение

Для выполнения запускаем так:
```bash
minikube delete
minikube start

# Создайте namespace audit-zone с уровнем PodSecurity restricted
kubectl apply -f 01-create-namespace.yaml

# Разверните три манифеста с нарушениями
kubectl apply -f insecure-manifests/01-privileged-pod.yaml
kubectl apply -f insecure-manifests/02-hostpath-pod.yaml
kubectl apply -f insecure-manifests/03-root-user-pod.yaml

# Убедитесь, что манифесты НЕ проходят валидацию в audit-zone
# Error from server (Forbidden): error when creating "insecure-manifests/01-privileged-pod.yaml": pods "pod-privileged" is forbidden: violates PodSecurity
# Error from server (Forbidden): error when creating "insecure-manifests/02-hostpath-pod.yaml": pods "pod-hostpath" is forbidden: violates PodSecurity
# Error from server (Forbidden): error when creating "insecure-manifests/03-root-user-pod.yaml": pods "pod-root-user" is forbidden: violates PodSecurity

# Исправьте манифесты, чтобы они соответствовали политике
kubectl apply -f secure-manifests/01-secure.yaml # pod/pod-secure1 created
kubectl apply -f secure-manifests/02-secure.yaml # pod/pod-secure2 created
kubectl apply -f secure-manifests/03-secure.yaml # pod/pod-secure3 created

# Установка Gatekeeper
kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/v3.22.2/deploy/gatekeeper.yaml

# Настройте OPA Gatekeeper с набором правил
kubectl apply -f gatekeeper/constraint-templates/
kubectl apply -f gatekeeper/constraints/

# Проверяем, что Gatekeeper создал ограничения
kubectl get constrainttemplates
kubectl get k8sdenyprivileged
kubectl get k8sdenyhostpath
kubectl get k8srequirerunasnonroot
```

Проверочные скрипты:

```bash
bash verify/verify-admission.sh
bash verify/validate-security.sh
```

## Описание задания
В кластере происходят развёртывания подов, которые нарушают требования безопасной конфигурации. Ваша задача — выявить такие случаи и организовать аудит.

### **Что нужно сделать:**

1. **Создайте namespace audit-zone с уровнем PodSecurity restricted.**
2. **Разверните три манифеста с нарушениями** в `insecure-manifests/`:
    - 01-privileged-pod.yaml — включает `privileged: true`.
    - 02-hostpath-pod.yaml — монтирует `hostPath`.
    - 03-root-user-pod.yaml — запускается от root (UID 0).
3. **Убедитесь, что манифесты НЕ проходят валидацию в audit-zone** (если всё верно, admission controller их заблокирует).
4. **Исправьте манифесты, чтобы они соответствовали политике**, сохраните в `secure-manifests/`.
5. **Настройте OPA Gatekeeper с набором правил:**
    - Нельзя использовать `privileged: true`.
    - Только `runAsNonRoot: true`.
    - `readOnlyRootFilesystem: true` обязательно.
    - `hostPath` запрещён.

Пример манифеста:

```
apiVersion: v1
kind: Pod
metadata:
  name: pod-privileged
  namespace: audit-zone
spec:
  containers:
    - name: nginx
      image: nginx
      securityContext:
        privileged: true 
```

Аналогично — hostPath и UID 0.

### **Как проверить самостоятельно:**

- **Политики работают** — небезопасные поды отклоняются.
- **Безопасные поды проходят валидацию.**
- **Gatekeeper активно применяет ограничения.**
- **PodSecurity Admission включён и действует**

Когда вы выполните задание, у вас должна получиться такая структура файлов:

```
Task7/
├── 01-create-namespace.yaml
├── insecure-manifests/
│   ├── 01-privileged-pod.yaml
│   ├── 02-hostpath-pod.yaml
│   └── 03-root-user-pod.yaml
├── secure-manifests/
│   ├── 01-secure.yaml
│   ├── 02-secure.yaml
│   └── 03-secure.yaml
├── gatekeeper/
│   ├── constraint-templates/
│   │   ├── privileged.yaml
│   │   ├── hostpath.yaml
│   │   └── runasnonroot.yaml
│   └── constraints/
│       ├── privileged.yaml
│       ├── hostpath.yaml
│       └── runasnonroot.yaml
├── verify/
│   ├── verify-admission.sh
│   └── validate-security.sh
├── audit-policy.yaml
├── README_FOR_REVIEWER.md 
```

Когда будете сдавать работу, загрузите файлы в директорию **Task7** в рамках пул-реквеста.

