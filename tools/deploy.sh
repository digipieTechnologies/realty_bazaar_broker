#!/bin/bash

# ==============================================================================
# REALTY BAZAAR BROKER - DEPLOYMENT & BUILD CLI
# ==============================================================================
# Interactive and automated CLI to clean, build, and deploy the Realty Bazaar
# Broker application across Development and Production environments for Web,
# Android, and iOS.
# ==============================================================================

# Exit immediately if an unhandled command fails
set -e

# Terminal Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Define absolute workspace directory relative to script path
WORKSPACE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$WORKSPACE"

# Helper function to detect FVM (Flutter Version Manager)
FLUTTER_CMD="flutter"
if [ -d ".fvm" ]; then
    if command -v fvm &> /dev/null; then
        FLUTTER_CMD="fvm flutter"
    fi
fi

# Environment Configuration Files
DEV_ENV_FILE=".env.dev"
PROD_ENV_FILE=".env.prod"

# Firebase Hosting Configuration
FIREBASE_PROJECT="the-realty-bazaar"
DEV_HOSTING_TARGET="dev"           # Target dev -> the-realty-bazaar-broker-dev
PROD_HOSTING_TARGET="partners"     # Target partners -> the-realty-bazaar-broker (partners.therealtybazaar.com)

# Validate environment files
validate_env_file() {
    local env_file="$1"
    local env_name="$2"
    if [ ! -f "$env_file" ]; then
        echo -e "${RED}✖ Error: '$env_file' ($env_name) not found in workspace root ($WORKSPACE).${NC}"
        echo -e "${YELLOW}Please create '$env_file' before running $env_name builds.${NC}"
        return 1
    else
        return 0
    fi
}

print_banner() {
    clear
    echo -e "${CYAN}${BOLD}"
    echo "======================================================================"
    echo "    ____  ______ ___   __  _________  __   ____  ___ _____ ___   ___  "
    echo "   / __ \/ ____//   | / / /_  __/\ \/ /  / __ )/   /__  //   | /   | "
    echo "  / /_/ / __/  / /| |/ /   / /    \  /  / __  / /| | / // /| |/ /| | "
    echo " / _, _/ /___ / ___ / /___/ /     / /  / /_/ / ___ |/ // ___ / ___ | "
    echo "/_/ |_/_____//_/  |_\____/_/     /_/  /_____/_/  |_/___/_/  |_\_/  |_|"
    echo "                                                                      "
    echo "     R E A L T Y   B A Z A A R   B R O K E R   -   D E P L O Y E R    "
    echo "======================================================================"
    echo -e "${NC}"

    echo -e "${CYAN}----------------------------------------------------------------------${NC}"
    echo -e "Workspace:        ${BOLD}$WORKSPACE${NC}"
    echo -e "Flutter:          ${BOLD}$($FLUTTER_CMD --version 2>/dev/null | head -n 1)${NC}"
    echo -e "Firebase Project: ${BOLD}$FIREBASE_PROJECT${NC}"
    echo -e "Dev Env (.env.dev):  $([ -f "$DEV_ENV_FILE" ] && echo -e "${GREEN}✔ Present${NC}" || echo -e "${RED}✖ Missing${NC}")"
    echo -e "Prod Env (.env.prod): $([ -f "$PROD_ENV_FILE" ] && echo -e "${GREEN}✔ Present${NC}" || echo -e "${RED}✖ Missing${NC}")"
    echo -e "Targets:          ${YELLOW}dev${NC} (the-realty-bazaar-broker-dev.web.app)"
    echo -e "                  ${GREEN}partners${NC} (partners.therealtybazaar.com / the-realty-bazaar-broker.web.app)"
    echo -e "${CYAN}----------------------------------------------------------------------${NC}"
    echo ""
}

# Helper to run a step with timing and clear output
run_step() {
    local step_name="$1"
    local cmd="$2"

    echo -e "\n${BLUE}➤ Running: ${BOLD}${step_name}...${NC}"
    echo -e "${CYAN}Command: $cmd${NC}\n"

    local start_time=$(date +%s)
    eval "$cmd"
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))

    echo -e "\n${GREEN}✔ Completed: ${BOLD}${step_name}${NC} in ${YELLOW}${duration}s${NC}"
}

# ------------------------------------------------------------------------------
# Build & Deploy Operations
# ------------------------------------------------------------------------------

# Web Builds
build_web_dev() {
    validate_env_file "$DEV_ENV_FILE" "Development"
    run_step "Web Build [DEV]" "$FLUTTER_CMD build web --release --dart-define-from-file=$DEV_ENV_FILE"
}

build_web_prod() {
    validate_env_file "$PROD_ENV_FILE" "Production"
    run_step "Web Build [PROD / PARTNERS]" "$FLUTTER_CMD build web --release --dart-define-from-file=$PROD_ENV_FILE"
}

# Web Deploys
deploy_web_dev() {
    run_step "Firebase Deploy to Hosting [DEV: $DEV_HOSTING_TARGET]" \
        "firebase deploy --only hosting:$DEV_HOSTING_TARGET --project $FIREBASE_PROJECT"
}

deploy_web_prod() {
    run_step "Firebase Deploy to Hosting [PROD: $PROD_HOSTING_TARGET]" \
        "firebase deploy --only hosting:$PROD_HOSTING_TARGET --project $FIREBASE_PROJECT"
}

# Web Build & Deploy Combined
build_and_deploy_web_dev() {
    build_web_dev
    deploy_web_dev
    echo -e "\n${GREEN}${BOLD}✔ Dev Web deployed to: https://the-realty-bazaar-broker-dev.web.app${NC}"
}

build_and_deploy_web_prod() {
    build_web_prod
    deploy_web_prod
    echo -e "\n${GREEN}${BOLD}✔ Production Web deployed to: https://partners.therealtybazaar.com${NC}"
    echo -e "${GREEN}${BOLD}  (Also live on: https://the-realty-bazaar-broker.web.app)${NC}"
}

build_and_deploy_web_both() {
    echo -e "\n${YELLOW}${BOLD}➤ Starting Two-Stage Deployment (DEV then PROD/PARTNERS)...${NC}"
    build_and_deploy_web_dev
    build_and_deploy_web_prod
    echo -e "\n${GREEN}${BOLD}🎉 Both DEV and PARTNERS (PROD) Web targets deployed successfully!${NC}"
}

# Android Builds
build_android_apk_dev() {
    validate_env_file "$DEV_ENV_FILE" "Development"
    run_step "Android APK Build [DEV]" "$FLUTTER_CMD build apk --release --dart-define-from-file=$DEV_ENV_FILE"
}

build_android_apk_prod() {
    validate_env_file "$PROD_ENV_FILE" "Production"
    run_step "Android APK Build [PROD]" "$FLUTTER_CMD build apk --release --dart-define-from-file=$PROD_ENV_FILE"
}

build_android_appbundle_dev() {
    validate_env_file "$DEV_ENV_FILE" "Development"
    run_step "Android App Bundle Build [DEV]" "$FLUTTER_CMD build appbundle --release --dart-define-from-file=$DEV_ENV_FILE"
}

build_android_appbundle_prod() {
    validate_env_file "$PROD_ENV_FILE" "Production"
    run_step "Android App Bundle Build [PROD]" "$FLUTTER_CMD build appbundle --release --dart-define-from-file=$PROD_ENV_FILE"
}

build_android_both_prod() {
    build_android_appbundle_prod
    build_android_apk_prod
}

# iOS Builds
build_ios_ipa_dev() {
    validate_env_file "$DEV_ENV_FILE" "Development"
    run_step "iOS IPA Build [DEV]" "$FLUTTER_CMD build ipa --release --dart-define-from-file=$DEV_ENV_FILE"
}

build_ios_ipa_prod() {
    validate_env_file "$PROD_ENV_FILE" "Production"
    run_step "iOS IPA Build [PROD]" "$FLUTTER_CMD build ipa --release --dart-define-from-file=$PROD_ENV_FILE"
}

# Maintenance
run_clean_and_get() {
    run_step "Flutter Clean" "$FLUTTER_CMD clean"
    run_step "Flutter Pub Get" "$FLUTTER_CMD pub get"
}

show_targets_info() {
    run_step "Firebase Targets Status" "firebase target --project $FIREBASE_PROJECT"
}

# ------------------------------------------------------------------------------
# Interactive Menu
# ------------------------------------------------------------------------------
show_menu() {
    echo -e "${BOLD}Please select a deployment or build option:${NC}"
    echo -e "  ${CYAN}[1]${NC} Build Web & Deploy to ${YELLOW}DEV${NC} (target: ${YELLOW}$DEV_HOSTING_TARGET${NC}, env: ${YELLOW}$DEV_ENV_FILE${NC})"
    echo -e "  ${CYAN}[2]${NC} Build Web & Deploy to ${GREEN}PROD / PARTNERS${NC} (target: ${GREEN}$PROD_HOSTING_TARGET${NC}, env: ${GREEN}$PROD_ENV_FILE${NC})"
    echo -e "  ${CYAN}[3]${NC} Build & Deploy Web to ${PURPLE}BOTH${NC} (Dev & Partners Sequentially)"
    echo -e "  ${CYAN}[4]${NC} Build Web Only [${YELLOW}DEV${NC}]"
    echo -e "  ${CYAN}[5]${NC} Build Web Only [${GREEN}PROD / PARTNERS${NC}]"
    echo -e "  ${CYAN}[6]${NC} Deploy Web Only [${YELLOW}DEV${NC}]"
    echo -e "  ${CYAN}[7]${NC} Deploy Web Only [${GREEN}PROD / PARTNERS${NC}]"
    echo -e "  ${CYAN}[8]${NC} Build Android ${GREEN}Release APK${NC} (PROD)"
    echo -e "  ${CYAN}[9]${NC} Build Android ${YELLOW}Release APK${NC} (DEV)"
    echo -e "  ${CYAN}[10]${NC} Build Android ${GREEN}App Bundle${NC} (PROD)"
    echo -e "  ${CYAN}[11]${NC} Build Android ${PURPLE}BOTH${NC} (App Bundle & APK - PROD)"
    echo -e "  ${CYAN}[12]${NC} Build iOS ${GREEN}Release IPA${NC} (PROD)"
    echo -e "  ${CYAN}[13]${NC} Run Flutter ${PURPLE}Clean & Pub Get${NC}"
    echo -e "  ${CYAN}[14]${NC} View Firebase Targets Info"
    echo -e "  ${CYAN}[0]${NC} Exit"
    echo ""
    read -rp "Enter choice [0-14]: " choice

    case $choice in
        1)  build_and_deploy_web_dev ;;
        2)  build_and_deploy_web_prod ;;
        3)  build_and_deploy_web_both ;;
        4)  build_web_dev ;;
        5)  build_web_prod ;;
        6)  deploy_web_dev ;;
        7)  deploy_web_prod ;;
        8)  build_android_apk_prod ;;
        9)  build_android_apk_dev ;;
        10) build_android_appbundle_prod ;;
        11) build_android_both_prod ;;
        12) build_ios_ipa_prod ;;
        13) run_clean_and_get ;;
        14) show_targets_info ;;
        0)
            echo -e "\n${BLUE}Have a great day!${NC}"
            exit 0
            ;;
        *)
            echo -e "\n${RED}Invalid selection. Please try again.${NC}\n"
            ;;
    esac
}

# ------------------------------------------------------------------------------
# Direct CLI Argument Execution
# ------------------------------------------------------------------------------
if [ "$1" != "" ]; then
    case "$1" in
        web-dev|--web-dev|dev|1)
            build_and_deploy_web_dev
            exit 0
            ;;
        web-prod|--web-prod|web-partners|partners|web|prod|2)
            build_and_deploy_web_prod
            exit 0
            ;;
        web-both|--web-both|3)
            build_and_deploy_web_both
            exit 0
            ;;
        build-web-dev|--build-web-dev|4)
            build_web_dev
            exit 0
            ;;
        build-web-prod|--build-web-prod|build-web-partners|5)
            build_web_prod
            exit 0
            ;;
        deploy-web-dev|--deploy-web-dev|6)
            deploy_web_dev
            exit 0
            ;;
        deploy-web-prod|--deploy-web-prod|deploy-web-partners|7)
            deploy_web_prod
            exit 0
            ;;
        apk-prod|--apk-prod|apk|8)
            build_android_apk_prod
            exit 0
            ;;
        apk-dev|--apk-dev|9)
            build_android_apk_dev
            exit 0
            ;;
        bundle-prod|appbundle-prod|--bundle|--appbundle|10)
            build_android_appbundle_prod
            exit 0
            ;;
        android-both|--android-both|11)
            build_android_both_prod
            exit 0
            ;;
        ios-prod|--ios-prod|ios|ipa|12)
            build_ios_ipa_prod
            exit 0
            ;;
        clean|--clean|13)
            run_clean_and_get
            exit 0
            ;;
        targets|--targets|14)
            show_targets_info
            exit 0
            ;;
        --help|-h|help)
            echo "Usage: ./tools/deploy.sh [command]"
            echo ""
            echo "Commands:"
            echo "  web-dev           Build & deploy web to DEV target (broker-dev)"
            echo "  web-prod (web)    Build & deploy web to PARTNERS target (partners.therealtybazaar.com)"
            echo "  web-both          Build & deploy web to both DEV and PARTNERS"
            echo "  build-web-dev     Build web release with .env.dev"
            echo "  build-web-prod    Build web release with .env.prod"
            echo "  deploy-web-dev    Deploy current build to DEV target"
            echo "  deploy-web-prod   Deploy current build to PARTNERS target"
            echo "  apk-dev           Build Android release APK with .env.dev"
            echo "  apk-prod (apk)    Build Android release APK with .env.prod"
            echo "  bundle-prod       Build Android App Bundle with .env.prod"
            echo "  android-both      Build Android App Bundle and APK (PROD)"
            echo "  ios-prod (ios)    Build iOS release IPA with .env.prod"
            echo "  clean             Run flutter clean and flutter pub get"
            echo "  targets           View Firebase hosting targets"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown argument: $1${NC}"
            echo -e "Run ${YELLOW}./tools/deploy.sh --help${NC} for available commands."
            exit 1
            ;;
    esac
fi

# Start interactive loop if no arguments provided
while true; do
    print_banner
    show_menu
    echo -e "\n${CYAN}----------------------------------------------------------------------${NC}"
    read -rp "Press Enter to return to the main menu..."
done
