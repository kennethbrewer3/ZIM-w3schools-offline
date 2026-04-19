#!/usr/bin/env bash
# =============================================================================
# install.sh
# Installer for the W3Schools offline archive.
#
# This script will:
#   1. Check dependencies
#   2. Clone the repo for W3Schools Offline locally. 
#   3. Build the ZIM file
#   4. Print deployment instructions
#
# Place this script in the "Build W3Schools ZIM" root folder.
#
# Usage:
#   chmod +x install.sh
#   ./install.sh
#
# To skip the download (if you already have the W3Schools repo):
#   ./install.sh --skip-clone
#
# To skip the ZIM build (just clone the repo):
#   ./install.sh --skip-zim
#
# To automatically deploy to a local Kiwix container after building:
#   ./install.sh --deploy --zim-dest /path/to/kiwix/library --container nomad_kiwix_server
#
# All options can be combined:
#   ./install.sh --skip-clone --deploy --zim-dest /opt/project-nomad/storage/zim --container nomad_kiwix_server
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HTML_DIR="${SCRIPT_DIR}/W3Schools_offline"
ZIM_OUT="${SCRIPT_DIR}/w3schools.zim"

ARCHIVE_URL="https://github.com/vahid-kazemi/W3Schools_offline"

SKIP_CLONE=0
SKIP_ZIM=0
DEPLOY=0
ZIM_DEST=""
CONTAINER=""

for arg in "$@"; do
  case $arg in
    --skip-clone)      SKIP_CLONE=1 ;;
    --skip-zim)        SKIP_ZIM=1 ;;
    --deploy)          DEPLOY=1 ;;
    --zim-dest=*)      ZIM_DEST="${arg#*=}" ;;
    --container=*)     CONTAINER="${arg#*=}" ;;
    *)                 echo "Unknown argument: $arg"; exit 1 ;;
  esac
done

# Validate deploy arguments
if [[ $DEPLOY -eq 1 ]]; then
  if [[ -z "$ZIM_DEST" ]]; then
    echo -e "${RED}[ERROR]${NC} --deploy requires --zim-dest=/path/to/kiwix/library"
    exit 1
  fi
  if [[ -z "$CONTAINER" ]]; then
    echo -e "${RED}[ERROR]${NC} --deploy requires --container=<container_name>"
    exit 1
  fi
fi

RED='\033[0;31m'; GRN='\033[0;32m'; YLW='\033[1;33m'
CYN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

banner() {
  echo -e "${YLW}"
  echo "  ╔══════════════════════════════════════════════════════════════╗"
  echo "  ║        W3SCHOOLS ARCHIVE -- INSTALLER                        ║"
  echo "  ║        PROJECT NOMAD // KIWIX OFFLINE SYSTEM                 ║"
  echo "  ╚══════════════════════════════════════════════════════════════╝"
  echo -e "${NC}"
}

check_deps() {
  echo -e "${BOLD}Checking dependencies...${NC}"
  local missing=0

  for cmd in git unzip python3; do
    if command -v "$cmd" &>/dev/null; then
      echo -e "  ${GRN}[OK]${NC}  $cmd"
    else
      echo -e "  ${RED}[MISSING]${NC}  $cmd"
      missing=1
    fi
  done

  if [[ $SKIP_ZIM -eq 0 ]]; then
    if command -v zimwriterfs &>/dev/null; then
      echo -e "  ${GRN}[OK]${NC}  zimwriterfs ($(zimwriterfs --version 2>&1 | head -1))"
    else
      echo -e "  ${RED}[MISSING]${NC}  zimwriterfs"
      echo -e "             Install with: sudo apt install zim-tools"
      missing=1
    fi
  fi

  if [[ $missing -eq 1 ]]; then
    echo ""
    echo -e "${RED}[ERROR]${NC} Missing dependencies. Install them and re-run."
    exit 1
  fi
  echo ""
}

clone_repo() {
  echo -e "${BOLD}Step 1: Cloning W3Schools archive from https://github.com/vahid-kazemi/W3Schools_offline.git${NC}"
  echo -e "  ${CYN}URL:${NC} ${ARCHIVE_URL}"
  echo ""
  echo -e "  This is a large download (~6GB). This will take a"
  echo -e "  while depending on your connection speed."
  echo ""

  if [[ -d "$HTML_DIR" ]]; then
    echo -e "  ${YLW}[INFO]${NC}  Found existing clone at ${HTML_DIR}"
    read -rp "  Re-use it? [Y/n]: " reuse
    reuse="${reuse:-Y}"
    if [[ "$reuse" =~ ^[Nn]$ ]]; then
      rm -rf "$HTML_DIR"
    fi
  fi

  if [[ ! -d "$HTML_DIR" ]]; then
    echo -e "  ${YLW}[GET]${NC}   Cloning repo..."
    git clone https://github.com/vahid-kazemi/W3Schools_offline.git
    echo ""
  fi

  if [[ -d "$HTML_DIR/www.w3schools.com/spaces" ]]; then
    echo -e "  ${YLW}[Removing bugged folder]${NC}"
    rm -rf $HTML_DIR/www.w3schools.com/spaces
  fi
}

build_zim() {
  echo -e "${BOLD}Step 2: Building ZIM file${NC}"

  if [[ ! -f "${HTML_DIR}/www.w3schools.com/index.html" ]]; then
    echo -e "  ${RED}[ERROR]${NC}  index.html not found at ${HTML_DIR}/www.w3schools.com/index.html"
    exit 1
  fi

  if [[ -d "$HTML_DIR/www.w3schools.com/spaces" ]]; then
    echo -e "  ${YLW}[Removing bugged folder]${NC}"
    rm -rf $HTML_DIR/www.w3schools.com/spaces
  fi

  echo -e "  ${CYN}Source:${NC}  ${HTML_DIR}"
  echo -e "  ${CYN}Output:${NC}  ${ZIM_OUT}"
  echo ""

  if [[ -f "$ZIM_OUT" ]]; then
    echo -e "  ${YLW}[INFO]${NC}  Removing existing $(basename "$ZIM_OUT")..."
    rm -f "$ZIM_OUT"
  fi

  echo -e "  ${YLW}[INFO]${NC}  Running zimwriterfs -- this will take several minutes..."
  echo "────────────────────────────────────────────────────────────────"

  zimwriterfs \
    --welcome=www.w3schools.com/index.html \
    --illustration="www.w3schools.com/images/w3schools_logo.png" \
    --language=eng \
    --name="w3schools" \
    --title="W3Schools Archive" \
    --description="Programming, HTML, CSS, Python, etc." \
    --longDescription="A collection of tutorials, and programming references, covering HTML, CSS, JavaScript, Python and more. Sourced from the w3schools.com." \
    --creator="The World Wide Web Consortium" \
    --publisher="ProjectNomad" \
    --tags="_category:programming;web development;_ftindex:yes" \
    --verbose \
    "$HTML_DIR" \
    "$ZIM_OUT"

  echo "────────────────────────────────────────────────────────────────"
  echo ""

  if [[ -f "$ZIM_OUT" ]]; then
    SIZE=$(du -sh "$ZIM_OUT" | cut -f1)
    echo -e "  ${GRN}[OK]${NC}  ZIM created: $(basename "$ZIM_OUT") (${SIZE})"
  else
    echo -e "  ${RED}[ERROR]${NC}  ZIM file not found after build."
    exit 1
  fi
  echo ""
}

deploy_instructions() {
  echo -e "${BOLD}Done. To deploy to Kiwix:${NC}"
  echo ""
  echo    "  1. Copy the ZIM file to your Kiwix library directory:"
  echo    "     cp w3schools.zim /your/kiwix/library/"
  echo ""
  echo    "  2. Set correct ownership (use the container's uid):"
  echo    "     KIWIX_UID=\$(sudo docker exec <kiwix_container> id -u)"
  echo    "     sudo chown \$KIWIX_UID:\$KIWIX_UID /your/kiwix/library/w3schools.zim"
  echo    "     sudo chown \$KIWIX_UID:\$KIWIX_UID /your/kiwix/library/kiwix-library.xml"
  echo ""
  echo    "  3. Register with Kiwix:"
  echo    "     sudo docker exec -u \$KIWIX_UID <kiwix_container> kiwix-manage \\"
  echo    "       /data/kiwix-library.xml add \\"
  echo    "       /data/w3schools.zim"
  echo ""
  echo    "  4. Restart the Kiwix container:"
  echo    "     sudo docker restart <kiwix_container>"
  echo ""
  echo    "  Or run this script with --deploy to do all of the above automatically:"
  echo    "     ./install.sh --skip-download --deploy \\"
  echo    "       --zim-dest=/your/kiwix/library \\"
  echo    "       --container=<kiwix_container>"
  echo ""
}

deploy() {
  local zim_name
  zim_name=$(basename "$ZIM_OUT")
  local dest_zim="${ZIM_DEST}/${zim_name}"
  local dest_xml="${ZIM_DEST}/kiwix-library.xml"

  echo -e "${BOLD}Step 3: Deploying to Kiwix${NC}"
  echo -e "  ${CYN}Container :${NC} ${CONTAINER}"
  echo -e "  ${CYN}Library   :${NC} ${ZIM_DEST}"
  echo ""

  # Check container is running
  if ! sudo docker inspect "$CONTAINER" &>/dev/null; then
    echo -e "  ${RED}[ERROR]${NC}  Container '${CONTAINER}' not found."
    exit 1
  fi

  # Get the uid the container runs as
  KIWIX_UID=$(sudo docker exec "$CONTAINER" id -u)
  echo -e "  ${YLW}[INFO]${NC}  Container runs as uid ${KIWIX_UID}"

  # Copy ZIM to destination
  echo -e "  ${YLW}[INFO]${NC}  Copying $(basename "$ZIM_OUT") to ${ZIM_DEST}..."
  sudo cp "$ZIM_OUT" "$dest_zim"

  # Fix ownership on ZIM and library XML
  echo -e "  ${YLW}[INFO]${NC}  Setting ownership to ${KIWIX_UID}:${KIWIX_UID}..."
  sudo chown "${KIWIX_UID}:${KIWIX_UID}" "$dest_zim"
  if [[ -f "$dest_xml" ]]; then
    sudo chown "${KIWIX_UID}:${KIWIX_UID}" "$dest_xml"
  fi

  # Remove ALL existing entries pointing at this ZIM file (handles duplicates from repeated deploys)
  echo -e "  ${YLW}[INFO]${NC}  Removing any existing entries for ${zim_name} from Kiwix library..."
  while true; do
    EXISTING_ID=$(sudo docker exec -u "$KIWIX_UID" "$CONTAINER" \
      kiwix-manage /data/kiwix-library.xml show 2>/dev/null | \
      grep -B5 "path:.*${zim_name}" | grep "^id:" | head -1 | awk '{print $2}' || true)

    if [[ -z "$EXISTING_ID" ]]; then
      break
    fi

    sudo docker exec -u "$KIWIX_UID" "$CONTAINER" \
      kiwix-manage /data/kiwix-library.xml remove "$EXISTING_ID"
    echo -e "  ${YLW}[INFO]${NC}  Removed entry: ${EXISTING_ID}"
  done

  # Add new ZIM to library
  echo -e "  ${YLW}[INFO]${NC}  Registering with Kiwix library..."
  sudo docker exec -u "$KIWIX_UID" "$CONTAINER" \
    kiwix-manage /data/kiwix-library.xml add "/data/${zim_name}"

  # Restart container
  echo -e "  ${YLW}[INFO]${NC}  Restarting ${CONTAINER}..."
  sudo docker restart "$CONTAINER"

  echo ""
  echo -e "  ${GRN}[OK]${NC}  Deployment complete. Kiwix is restarting."
  echo ""
}

# =============================================================================
banner
check_deps

if [[ $SKIP_CLONE -eq 0 ]]; then
  clone_repo 
else
  echo -e "${YLW}[INFO]${NC}  Skipping clone (--skip-clone)."
  echo ""
fi

if [[ $SKIP_ZIM -eq 0 ]]; then
  build_zim
else
  echo -e "${YLW}[INFO]${NC}  Skipping ZIM build (--skip-zim)."
  echo ""
fi

if [[ $DEPLOY -eq 1 ]]; then
  deploy
else
  deploy_instructions
fi
