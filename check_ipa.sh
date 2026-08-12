cat > /tmp/collect_telegram_diag.sh <<'SH'
#!/usr/bin/env bash
set +e

ROOT="$HOME/amneziafrok/Telegram-iOS"
OUT="/tmp/telegram_altstore_diag.txt"
IPA="$HOME/Downloads/Telegram-12.9.2-34481/AmneziaClient.ipa"

exec > >(tee "$OUT") 2>&1

echo "============================================================"
echo " TELEGRAM / ALTSTORE DIAGNOSTICS"
echo "============================================================"
date
echo "USER: $USER"
echo "HOME: $HOME"
echo "PWD:  $(pwd)"
echo "ROOT: $ROOT"
echo "IPA:   $IPA"
echo

echo "============================================================"
echo "1. SYSTEM"
echo "============================================================"
uname -a
echo
cat /etc/os-release 2>/dev/null
echo
echo "Python:"
python3 --version 2>&1
echo "OpenSSL:"
openssl version 2>&1
echo "Zip:"
zip -v 2>&1 | head -5
echo "Unzip:"
unzip -v 2>&1 | head -5
echo

echo "============================================================"
echo "2. REPOSITORY"
echo "============================================================"
cd "$ROOT" || exit 1

echo "Git:"
git status --short 2>&1
echo
git branch --show-current 2>&1
echo
git rev-parse HEAD 2>&1
echo
git log -1 --oneline 2>&1
echo

echo "Make.py:"
ls -lh build-system/Make/Make.py
echo

echo "============================================================"
echo "3. APPSTORE CONFIGURATION"
echo "============================================================"
cat build-system/appstore-configuration.json
echo

echo "============================================================"
echo "4. AVAILABLE CONFIG FILES"
echo "============================================================"
find build-system -maxdepth 4 -type f \
    \( -name "*.json" -o -name "*.mobileprovision" -o -name "*.plist" \) \
    -print 2>/dev/null | sort
echo

echo "============================================================"
echo "5. FAKE CODESIGNING"
echo "============================================================"
if [ -d build-system/fake-codesigning ]; then
    find build-system/fake-codesigning -maxdepth 4 -type f -print | sort
else
    echo "fake-codesigning directory NOT FOUND"
fi
echo

echo "============================================================"
echo "6. CODESIGNING REFERENCES IN BUILD SYSTEM"
echo "============================================================"
grep -RniE \
    "fake-codesigning|codesigningInformationPath|gitCodesigningRepository|xcodeManagedCodesigning|codesign|provisioning" \
    build-system/Make 2>/dev/null | head -300
echo

echo "============================================================"
echo "7. MAKE BUILD HELP"
echo "============================================================"
python3 build-system/Make/Make.py build --help 2>&1
echo

echo "============================================================"
echo "8. IPA FILE"
echo "============================================================"
if [ -f "$IPA" ]; then
    ls -lh "$IPA"
    file "$IPA"
    sha256sum "$IPA"
    echo
    echo "--- ZIP TEST ---"
    unzip -t "$IPA" 2>&1 | tail -20
else
    echo "IPA NOT FOUND: $IPA"
fi
echo

echo "============================================================"
echo "9. IPA CONTENTS / APP PATH"
echo "============================================================"
if [ -f "$IPA" ]; then
    unzip -l "$IPA" 2>/dev/null | grep -E \
        'Payload/[^/]+\.app/($|Info\.plist|embedded\.mobileprovision|_CodeSignature/CodeResources|[^/]+$)' \
        | head -150
fi
echo

echo "============================================================"
echo "10. DETECTED .APP"
echo "============================================================"
if [ -f "$IPA" ]; then
    unzip -l "$IPA" 2>/dev/null \
        | awk '{print $4}' \
        | grep -E '^Payload/[^/]+\.app/$' \
        | sort -u
fi
echo

APP_PATH=""
if [ -f "$IPA" ]; then
    APP_PATH=$(unzip -l "$IPA" 2>/dev/null \
        | awk '{print $4}' \
        | grep -E '^Payload/[^/]+\.app/$' \
        | head -1 \
        | sed 's#/$##')
fi

echo "Detected APP: $APP_PATH"
echo

echo "============================================================"
echo "11. INFO.PLIST"
echo "============================================================"
if [ -n "$APP_PATH" ]; then
    unzip -p "$IPA" "$APP_PATH/Info.plist" > /tmp/telegram_Info.plist 2>/dev/null

    if [ -s /tmp/telegram_Info.plist ]; then
        file /tmp/telegram_Info.plist

        python3 - <<'PY'
import plistlib

path="/tmp/telegram_Info.plist"

try:
    with open(path, "rb") as f:
        p=plistlib.load(f)

    keys=[
        "CFBundleIdentifier",
        "CFBundleName",
        "CFBundleDisplayName",
        "CFBundleShortVersionString",
        "CFBundleVersion",
        "MinimumOSVersion",
        "UIDeviceFamily",
    ]

    for k in keys:
        print(f"{k}: {p.get(k)}")

except Exception as e:
    print("PLIST ERROR:", repr(e))
PY
    else
        echo "Could not extract Info.plist"
    fi
fi
echo

echo "============================================================"
echo "12. MAIN EXECUTABLE"
echo "============================================================"
if [ -n "$APP_PATH" ]; then
    unzip -l "$IPA" 2>/dev/null \
        | awk '{print $4}' \
        | grep -E "^${APP_PATH}/[^/]+$" \
        | grep -vE '/(Info\.plist|embedded\.mobileprovision)$' \
        | head -100
fi
echo

echo "============================================================"
echo "13. EMBEDDED MOBILEPROVISION"
echo "============================================================"
if [ -n "$APP_PATH" ]; then
    unzip -p "$IPA" "$APP_PATH/embedded.mobileprovision" \
        > /tmp/telegram_embedded.mobileprovision 2>/dev/null

    if [ -s /tmp/telegram_embedded.mobileprovision ]; then
        ls -lh /tmp/telegram_embedded.mobileprovision
        file /tmp/telegram_embedded.mobileprovision

        echo
        echo "--- OPENSSL VERIFY ---"
        openssl smime \
            -inform DER \
            -verify \
            -in /tmp/telegram_embedded.mobileprovision \
            -noverify \
            -out /tmp/telegram_profile.plist 2>&1

        echo
        echo "--- PROFILE DATA ---"

        python3 - <<'PY'
import plistlib
from datetime import datetime

path="/tmp/telegram_profile.plist"

try:
    with open(path,"rb") as f:
        p=plistlib.load(f)

    print("Name:", p.get("Name"))
    print("UUID:", p.get("UUID"))
    print("TeamName:", p.get("TeamName"))
    print("TeamIdentifier:", p.get("TeamIdentifier"))
    print("ExpirationDate:", p.get("ExpirationDate"))
    print("ProvisionedDevices:", p.get("ProvisionedDevices"))

    e=p.get("Entitlements",{})

    print()
    print("application-identifier:", e.get("application-identifier"))
    print("com.apple.developer.team-identifier:",
          e.get("com.apple.developer.team-identifier"))
    print("get-task-allow:", e.get("get-task-allow"))
    print("keychain-access-groups:", e.get("keychain-access-groups"))
    print("application-groups:", e.get("com.apple.security.application-groups"))
    print("aps-environment:", e.get("aps-environment"))

except Exception as ex:
    print("PROFILE PARSE ERROR:", repr(ex))
PY
    else
        echo "No embedded.mobileprovision found"
    fi
fi
echo

echo "============================================================"
echo "14. CODE SIGNATURE FILES"
echo "============================================================"
if [ -n "$APP_PATH" ]; then
    unzip -l "$IPA" 2>/dev/null \
        | grep -E "${APP_PATH}/(_CodeSignature|embedded\.mobileprovision)" \
        | head -100
fi
echo

echo "============================================================"
echo "15. ALL EMBEDDED PROFILES"
echo "============================================================"
if [ -f "$IPA" ]; then
    unzip -l "$IPA" 2>/dev/null \
        | grep -E 'embedded\.mobileprovision$'
fi
echo

echo "============================================================"
echo "16. ALL APPEX / FRAMEWORKS"
echo "============================================================"
if [ -f "$IPA" ]; then
    unzip -l "$IPA" 2>/dev/null \
        | grep -E '\.(appex|framework)/$' \
        | head -100
fi
echo

echo "============================================================"
echo "17. BUNDLE IDS FROM ALL INFO.PLIST FILES"
echo "============================================================"
TMPDIR_DIAG=$(mktemp -d)

if [ -f "$IPA" ]; then
    unzip -q "$IPA" -d "$TMPDIR_DIAG" 2>/dev/null

    find "$TMPDIR_DIAG" -name Info.plist -type f -print0 2>/dev/null |
    while IFS= read -r -d '' f; do
        python3 - "$f" <<'PY'
import sys, plistlib, os

path=sys.argv[1]

try:
    with open(path,"rb") as fh:
        p=plistlib.load(fh)

    print(
        os.path.relpath(path, sys.argv[1].split("/Info.plist")[0])
        if False else path
    )
    print("  Bundle ID:", p.get("CFBundleIdentifier"))
    print("  Name:", p.get("CFBundleName"))
    print("  Version:", p.get("CFBundleShortVersionString"))
    print("  Build:", p.get("CFBundleVersion"))
except Exception as e:
    print("PLIST ERROR:", path, repr(e))
PY
        echo
    done
fi

echo "============================================================"
echo "18. ENTITLEMENTS / SIGNING TOOLS AVAILABLE"
echo "============================================================"
for cmd in codesign security xcrun otool lipo plutil; do
    printf "%-12s: " "$cmd"
    command -v "$cmd" 2>/dev/null || echo "NOT AVAILABLE"
done
echo

echo "============================================================"
echo "19. PROJECT SIGNING REFERENCES"
echo "============================================================"
grep -RniE \
    'C67CF9S4VU|ph\.telegra\.Telegraph|TeamIdentifier|DEVELOPMENT_TEAM|PRODUCT_BUNDLE_IDENTIFIER|CODE_SIGN' \
    --exclude-dir=.git \
    --exclude='*.pbxproj' \
    . 2>/dev/null | head -250
echo

echo "============================================================"
echo "20. MAKE PY SIGNING LOGIC"
echo "============================================================"
sed -n '430,490p' build-system/Make/Make.py 2>/dev/null
echo
sed -n '830,870p' build-system/Make/Make.py 2>/dev/null
echo
sed -n '1200,1245p' build-system/Make/Make.py 2>/dev/null
echo

echo "============================================================"
echo "21. ENVIRONMENT — SAFE SIGNING VARIABLES ONLY"
echo "============================================================"
env | grep -E '^(TELEGRAM_|APPLE_|CODESIGN|DEVELOPMENT_TEAM)' \
    | sed -E 's/(PASSWORD|PRIVATE_KEY|TOKEN|SECRET|KEY)=.*/\1=<REDACTED>/' \
    || true
echo

echo "============================================================"
echo "22. AVAILABLE SIGNING DIRECTORIES"
echo "============================================================"
find "$ROOT" -maxdepth 5 -type d \
    \( -iname '*sign*' -o -iname '*cert*' -o -iname '*profile*' \) \
    -print 2>/dev/null | sort | head -150
echo

echo "============================================================"
echo "23. PROFILE FILE METADATA"
echo "============================================================"
find "$ROOT" -type f -name "*.mobileprovision" -print0 2>/dev/null |
while IFS= read -r -d '' f; do
    echo "--- $f"
    ls -lh "$f"

    openssl smime \
        -inform DER \
        -verify \
        -in "$f" \
        -noverify \
        -out /tmp/profile_diag.plist >/dev/null 2>&1

    if [ -s /tmp/profile_diag.plist ]; then
        python3 - <<'PY'
import plistlib

try:
    with open("/tmp/profile_diag.plist","rb") as fh:
        p=plistlib.load(fh)

    print("Name:",p.get("Name"))
    print("TeamIdentifier:",p.get("TeamIdentifier"))
    print("UUID:",p.get("UUID"))
    print("ExpirationDate:",p.get("ExpirationDate"))
    print("Application ID:",
          p.get("Entitlements",{}).get("application-identifier"))
except Exception as e:
    print("parse error:",repr(e))
PY
    fi
done
echo

echo "============================================================"
echo "24. DIAGNOSTIC FILE"
echo "============================================================"
echo "Saved to:"
echo "$OUT"
echo
wc -l "$OUT"
echo
echo "============================================================"
echo " END"
echo "============================================================"
SH

chmod +x /tmp/collect_telegram_diag.sh
/tmp/collect_telegram_diag.sh
