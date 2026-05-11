#!/usr/bin/env bash
set -e

mkdir -p users-certs

# Создаем неймспейсы если они не существуют
for ns in test project1 project2; do
  kubectl get ns "$ns" >/dev/null 2>&1 || kubectl create ns "$ns"
done

# Создаем пользователей
for user in dev1:test dev2:test sre-project1:project1 sre-project2:project2 devops:default; do
  name="${user%%:*}"
  namespace="${user##*:}"

  openssl genrsa -out "users-certs/$name.key" 2048
  openssl req -new -key "users-certs/$name.key" -out "users-certs/$name.csr" -subj "/CN=$name"

  openssl x509 -req \
    -in "users-certs/$name.csr" \
    -CA "$HOME/.minikube/ca.crt" \
    -CAkey "$HOME/.minikube/ca.key" \
    -CAcreateserial \
    -out "users-certs/$name.crt" \
    -days 365

  kubectl config set-credentials "$name" \
    --client-certificate="users-certs/$name.crt" \
    --client-key="users-certs/$name.key"

  kubectl config set-context "$name" \
    --cluster=minikube \
    --user="$name" \
    --namespace="$namespace"
done
