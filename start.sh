#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# LONGEVITY — Automatisierter Dev- & Onboarding-Flow
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# ANSI Farbcodes
BOLD="\033[1m"
GREEN="\033[0;32m"
BLUE="\033[0;34m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
CYAN="\033[0;36m"
NC="\033[0m" # No Color

COMPOSE_FILE="infra/compose.dev.yml"

log_info() {
  echo -e "${BLUE}${BOLD}==>${NC} ${BOLD}$1${NC}"
}

log_success() {
  echo -e "${GREEN}${BOLD}✔${NC} $1"
}

log_warn() {
  echo -e "${YELLOW}${BOLD}⚠${NC} $1"
}

log_error() {
  echo -e "${RED}${BOLD}✖${NC} $1"
}

# --- Befehls-Parser ---
ACTION="${1:-up}"

case "$ACTION" in
  down)
    log_info "Stoppe LONGEVITY Entwicklungsumgebung..."
    docker compose -f "$COMPOSE_FILE" down
    log_success "Alle Container gestoppt."
    exit 0
    ;;
  restart)
    log_info "Starte LONGEVITY Entwicklungsumgebung neu..."
    docker compose -f "$COMPOSE_FILE" down
    ACTION="up"
    ;;
  logs)
    shift || true
    docker compose -f "$COMPOSE_FILE" logs -f "$@"
    exit 0
    ;;
  seed)
    SEED_TYPE="${2:-full}"
    if [ "$SEED_TYPE" = "demo" ] || [ "$SEED_TYPE" = "minimal" ]; then
      log_info "Lade minimales Demo-Dataset in die Datenbank..."
      docker compose -f "$COMPOSE_FILE" exec -T api pnpm seed:demo || \
        docker compose -f "$COMPOSE_FILE" exec -T api node dist/seed/demo.js
      docker compose -f "$COMPOSE_FILE" exec -T api pnpm seed:demo-insurer || \
        docker compose -f "$COMPOSE_FILE" exec -T api node dist/seed/demoInsurer.js || true
      docker compose -f "$COMPOSE_FILE" exec -T api pnpm seed:admin || \
        docker compose -f "$COMPOSE_FILE" exec -T api node dist/seed/adminUser.js || true
      docker compose -f "$COMPOSE_FILE" exec -T api pnpm seed:offers || \
        docker compose -f "$COMPOSE_FILE" exec -T api node dist/seed/offers.js || true
      log_success "Minimales Demo-Dataset erfolgreich initialisiert."
    else
      log_info "Lade vollständiges Demo-Dataset (alle Krankenkassen, Anfragen, User & Scores)..."
      docker compose -f "$COMPOSE_FILE" exec -T api pnpm seed:full || \
        docker compose -f "$COMPOSE_FILE" exec -T api node dist/seed/fullDemo.js
      log_success "Vollständiges Demo-Dataset erfolgreich initialisiert."
    fi
    echo ""
    echo -e "  ${BOLD}Demo-Zugangsdaten:${NC}"
    echo -e "  • ${BOLD}Nutzer-Login:${NC}        demo@longevity.app / demo-longevity-2026"
    echo -e "  • ${BOLD}Insurer-Login:${NC}       insurer-demo@longevity.app / insurer-longevity-2026"
    echo -e "  • ${BOLD}Platform-Admin:${NC}      admin@longevity.app / admin-longevity-2026"
    echo -e "  • ${BOLD}Weitere Kassen:${NC}      <kasse>-admin@longevity.app / demo-longevity-2026 (tk, barmer, aok, ottonova)"
    exit 0
    ;;
  clean)
    log_warn "Achtung: Dies löscht alle Container UND Datenbank-Volumes!"
    read -p "Fortfahren? (y/N): " -r CONFIRM
    if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
      docker compose -f "$COMPOSE_FILE" down -v --remove-orphans
      log_success "Umgebung und Volumes bereinigt."
    else
      echo "Abgebrochen."
    fi
    exit 0
    ;;
  help|--help|-h)
    echo "Verwendung: ./start.sh [Befehl]"
    echo ""
    echo "Befehle:"
    echo "  (kein Befehl) / up   Startet kompletten Setup-Flow (Submodule, Keys, Docker, DB, Seed)"
    echo "  down                 Stoppt alle Container"
    echo "  restart              Stoppt und startet alle Container neu"
    echo "  logs [service]       Zeigt Live-Logs der Container (z. B. ./start.sh logs api)"
    echo "  seed [full|demo]     Führt den Demo-Datenseed erneut aus (Standard: full, optional: demo)"
    echo "  clean                Stoppt Container und löscht Docker-Volumes (Reset)"
    echo "  help                 Zeigt diese Hilfe an"
    exit 0
    ;;
  up)
    ;;
  *)
    log_error "Unbekannter Befehl: $ACTION"
    echo "Verwende './start.sh help' für eine Übersicht."
    exit 1
    ;;
esac

echo -e "${CYAN}${BOLD}"
echo "  _     ___  _   _  ____ _______     _____ _______   __"
echo " | |   / _ \| \ | |/ ___| ____\ \   / /_ _|_   _\ \ / /"
echo " | |  | | | |  \| | |  _|  _|  \ \ / / | |  | |  \ V / "
echo " | |__| |_| | |\  | |_| | |___  \ V /  | |  | |   | |  "
echo " |_____\___/|_| \_|\____|_____|  \_/  |___| |_|   |_|  "
echo -e "${NC}"
echo "Starte automatisiertes Setup für die lokale Entwicklung..."
echo ""

# ------------------------------------------------------------------------------
# 1. Voraussetzungen prüfen
# ------------------------------------------------------------------------------
log_info "Schritt 1/6: Voraussetzungen prüfen..."

if ! command -v docker >/dev/null 2>&1; then
  log_error "Docker ist nicht installiert. Bitte Docker installieren: https://docs.docker.com/get-docker/"
  exit 1
fi

if ! docker compose version >/dev/null 2>&1; then
  log_error "'docker compose' ist nicht verfügbar. Bitte Docker Compose v2 aktivieren."
  exit 1
fi

if ! docker info >/dev/null 2>&1; then
  DOCKER_ERR=$(docker info 2>&1 || true)
  if echo "$DOCKER_ERR" | grep -qi "permission denied"; then
    log_error "Keine Berechtigung für den Docker-Socket (Permission denied)."
    echo -e "  ${YELLOW}Tipp:${NC} Führe 'sudo usermod -aG docker \$USER && newgrp docker' aus oder starte mit 'sudo ./start.sh'."
  else
    log_error "Der Docker-Daemon läuft nicht. Bitte starte Docker Desktop bzw. den dockerd-Dienst."
  fi
  exit 1
fi

log_success "Docker und Docker Compose sind einsatzbereit."

# ------------------------------------------------------------------------------
# 2. Git-Submodule synchronisieren
# ------------------------------------------------------------------------------
log_info "Schritt 2/6: Git-Submodule prüfen & initialisieren..."

if [ -d ".git" ]; then
  git submodule update --init --recursive
  log_success "Submodule erfolgreich synchronisiert (backend & frontend)."
else
  log_warn "Kein .git-Verzeichnis gefunden (Archiv-Download). Überspringe 'git submodule'."
  if [ ! -d "backend" ] || [ ! -d "frontend" ]; then
    log_error "Verzeichnisse 'backend' oder 'frontend' fehlen. Bitte stelle sicher, dass alle Unterordner entpackt wurden."
    exit 1
  fi
fi

# ------------------------------------------------------------------------------
# 3. Ed25519 Signing Keys & infra/.env prüfen
# ------------------------------------------------------------------------------
log_info "Schritt 3/6: Ed25519 Signing Keys & infra/.env konfigurieren..."

mkdir -p infra

if [ ! -f "infra/.env" ] || ! grep -q "SIGNING_KEY_PRIVATE" "infra/.env"; then
  if command -v openssl >/dev/null 2>&1; then
    log_info "Generiere neues Ed25519 Schlüsselpaar via OpenSSL..."
    PRIV_KEY=$(openssl genpkey -algorithm ed25519 2>/dev/null)
    PUB_KEY=$(echo "$PRIV_KEY" | openssl pkey -pubout 2>/dev/null)
    
    cat <<EOF > infra/.env
SIGNING_KEY_PRIVATE="$PRIV_KEY"
SIGNING_KEY_PUBLIC="$PUB_KEY"
EOF
    log_success "Ed25519 Schlüsselpaar automatisch in infra/.env generiert."
  elif [ -f "signing_key.pem" ] && [ -f "signing_key_pub.pem" ]; then
    PRIV_KEY=$(cat signing_key.pem)
    PUB_KEY=$(cat signing_key_pub.pem)
    cat <<EOF > infra/.env
SIGNING_KEY_PRIVATE="$PRIV_KEY"
SIGNING_KEY_PUBLIC="$PUB_KEY"
EOF
    log_success "Bestehende Schlüsseldateien in infra/.env übernommen."
  else
    log_error "Weder 'openssl' noch existierende Schlüsseldateien gefunden."
    log_error "Bitte generiere signing_key.pem und signing_key_pub.pem oder installiere openssl."
    exit 1
  fi
else
  log_success "infra/.env mit Signing Keys bereits vorhanden."
fi

# ------------------------------------------------------------------------------
# 4. Docker Compose Container bauen & starten
# ------------------------------------------------------------------------------
log_info "Schritt 4/6: Docker Container bauen & starten (im Hintergrund)..."

docker compose -f "$COMPOSE_FILE" up --build -d

log_success "Container gestartet (db, mailpit, api, web)."

# ------------------------------------------------------------------------------
# 5. Auf Datenbank-Readiness warten
# ------------------------------------------------------------------------------
log_info "Schritt 5/6: Warten auf Datenbank-Bereitschaft (Postgres)..."

RETRIES=30
until docker compose -f "$COMPOSE_FILE" exec -T db pg_isready -U longevity >/dev/null 2>&1 || [ $RETRIES -eq 0 ]; do
  sleep 1
  RETRIES=$((RETRIES - 1))
done

if [ $RETRIES -eq 0 ]; then
  log_error "Datenbank konnte innerhalb des Timeouts nicht erreicht werden."
  docker compose -f "$COMPOSE_FILE" logs db
  exit 1
fi

log_success "PostgreSQL ist betriebsbereit."

# ------------------------------------------------------------------------------
# 6. Datenbank migrieren & Demo-Daten seeden (Full Dataset)
# ------------------------------------------------------------------------------
log_info "Schritt 6/6: Schema-Migrationen anwenden & vollständiges Demo-Dataset seeden..."

# Migrationen
if ! docker compose -f "$COMPOSE_FILE" exec -T api pnpm db:migrate 2>/dev/null; then
  log_info "Fallback auf kompilierte Migrationen..."
  docker compose -f "$COMPOSE_FILE" exec -T api node dist/db/migrate.js
fi
log_success "Datenbank-Migrationen erfolgreich angewendet."

# Vollständiges Demo-Dataset
if ! docker compose -f "$COMPOSE_FILE" exec -T api pnpm seed:full 2>/dev/null; then
  log_info "Fallback auf kompilierte Full-Demo-Seeds..."
  docker compose -f "$COMPOSE_FILE" exec -T api node dist/seed/fullDemo.js
fi
log_success "Vollständiges Demo-Dataset (alle Krankenkassen, Nutzer, Angebote & Scores) erfolgreich initialisiert."

echo ""
echo -e "${GREEN}${BOLD}================================================================${NC}"
echo -e "${GREEN}${BOLD}  🎉 LONGEVITY Entwicklungsumgebung erfolgreich gestartet!      ${NC}"
echo -e "${GREEN}${BOLD}================================================================${NC}"
echo ""
echo -e "  ${BOLD}Dienste & Web-Oberflächen:${NC}"
echo -e "  • ${CYAN}Frontend:${NC}     http://localhost:5173"
echo -e "  • ${CYAN}API & Docs:${NC}   http://localhost:3000/api/healthz"
echo -e "  • ${CYAN}Mailpit:${NC}      http://localhost:8025  ${YELLOW}(fängt alle Bestätigungs- & Reset-Mails ab)${NC}"
echo ""
echo -e "  ${BOLD}Demo-Zugangsdaten:${NC}"
echo -e "  • ${BOLD}Nutzer-Login:${NC}        demo@longevity.app / demo-longevity-2026"
echo -e "  • ${BOLD}Insurer-Login:${NC}       insurer-demo@longevity.app / insurer-longevity-2026"
echo -e "  • ${BOLD}Platform-Admin:${NC}      admin@longevity.app / admin-longevity-2026"
echo -e "  • ${BOLD}Weitere Kassen:${NC}      <kasse>-admin@longevity.app / demo-longevity-2026 (tk, barmer, aok, ottonova)"
echo ""
echo -e "  ${BOLD}Hilfreiche Befehle:${NC}"
echo -e "  • Logs ansehen:  ${CYAN}./start.sh logs${NC} (oder z. B. ./start.sh logs api)"
echo -e "  • Re-Seed:       ${CYAN}./start.sh seed${NC} (Standard: full)"
echo -e "  • Stoppen:       ${CYAN}./start.sh down${NC}"
echo ""
echo -e "${GREEN}${BOLD}================================================================${NC}"
