#!/usr/bin/env bash
# PROG5 — Vérification de l'environnement (macOS, Linux, WSL)
# Usage : ./check-env.sh
# Le résultat est aussi écrit dans check-env-result.txt, à pousser sur votre dépôt.

JAVA_MIN=21
NODE_MIN=24
PHP_MIN_ID=80400          # PHP 8.4
PG_IMAGE="postgres:17"
GUIDE="https://hei-lms.app"
OUT="check-env-result.txt"

errors=0
: > "$OUT"

log() { printf '%s\n' "$1" | tee -a "$OUT"; }
ok()  { log "[OK] $1"; }
ko()  { log "[KO] $1"; errors=$((errors + 1)); }
has() { command -v "$1" >/dev/null 2>&1; }
major() { printf '%s' "$1" | sed -E 's/^[^0-9]*([0-9]+).*/\1/'; }

log "PROG5 — vérification de l'environnement"
log "Date    : $(date '+%Y-%m-%d %H:%M')"
log "Système : $(uname -s) $(uname -m)"
log ""

# 1. Git ------------------------------------------------------------------
check_git() {
  if ! has git; then ko "git : introuvable"; return; fi
  local v name email
  v=$(git --version | awk '{print $3}')
  name=$(git config --global user.name)
  email=$(git config --global user.email)
  if [ -z "$name" ] || [ -z "$email" ]; then
    ko "git $v : identité non configurée (git config --global user.name / user.email)"
  else
    ok "git $v ($name <$email>)"
  fi
}

# 2. Java + Maven ---------------------------------------------------------
check_java() {
  if ! has java; then ko "java : introuvable (JDK $JAVA_MIN requis)"; return; fi
  if ! has mvn;  then ko "mvn : introuvable"; return; fi
  local jv mv
  jv=$(java -version 2>&1 | grep -m1 'version "' | sed -E 's/.*version "([^"]+)".*/\1/')
  mv=$(mvn -v 2>/dev/null | grep -m1 'Apache Maven' | awk '{print $3}')
  if [ "$(major "$jv")" -ge "$JAVA_MIN" ] 2>/dev/null; then
    ok "java $jv, mvn $mv"
  else
    ko "java $jv : version trop ancienne (JDK $JAVA_MIN requis)"
  fi
}

# 3. Node.js + npm --------------------------------------------------------
check_node() {
  if ! has node; then ko "node : introuvable (Node.js $NODE_MIN LTS requis)"; return; fi
  if ! has npm;  then ko "npm : introuvable"; return; fi
  local nv pv
  nv=$(node -v)
  pv=$(npm -v)
  if [ "$(major "$nv")" -ge "$NODE_MIN" ] 2>/dev/null; then
    ok "node $nv, npm $pv"
  else
    ko "node $nv : version trop ancienne (Node.js $NODE_MIN LTS requis)"
  fi
}

# 4. PHP + Composer + Symfony CLI -----------------------------------------
check_php() {
  if ! has php;      then ko "php : introuvable (PHP 8.4 requis)"; return; fi
  if ! has composer; then ko "composer : introuvable"; return; fi
  if ! has symfony;  then ko "symfony : CLI introuvable"; return; fi
  local id v cv
  id=$(php -r 'echo PHP_VERSION_ID;')
  v=$(php -r 'echo PHP_VERSION;')
  cv=$(composer --version 2>/dev/null | grep -m1 'Composer version' | awk '{print $3}')
  if [ "$id" -lt "$PHP_MIN_ID" ] 2>/dev/null; then
    ko "php $v : version trop ancienne (PHP 8.4 requis)"; return
  fi
  if symfony check:requirements >/dev/null 2>&1; then
    ok "php $v, composer $cv, symfony"
  else
    ko "php $v : extensions manquantes pour Symfony (lancez : symfony check:requirements)"
  fi
}

# 5. Docker + image PostgreSQL --------------------------------------------
check_docker() {
  if ! has docker; then ko "docker : introuvable"; return; fi
  if ! docker info >/dev/null 2>&1; then
    ko "docker : installé mais pas démarré (ou droits insuffisants)"; return
  fi
  if ! docker image inspect "$PG_IMAGE" >/dev/null 2>&1; then
    ko "docker OK, image $PG_IMAGE absente (lancez : docker pull $PG_IMAGE)"; return
  fi
  ok "docker $(docker version --format '{{.Server.Version}}' 2>/dev/null), image $PG_IMAGE"
}

check_git
check_java
check_node
check_php
check_docker

log ""
if [ "$errors" -eq 0 ]; then
  log "Environnement prêt pour PROG5"
  exit 0
else
  log "$errors point(s) à corriger avant la séance 2. Guide : $GUIDE"
  exit 1
fi
