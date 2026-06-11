#!/bin/bash
# eSign токен (FeiTian HyperPKI / ePass2003Auto) идэвхжүүлэгч
# Токен залгахад CD-ROM горимд гацдаг тул CD-г eject хийж CCID руу шилжүүлнэ.

echo "🔑 eSign токен идэвхжүүлж байна..."
echo ""

# Reader нэр аль драйвер идэвхтэйг заана:
#   FT ePass2003Auto    → FeiTian IFD драйвер, бүрэн ажиллана
#   HYPERSECU USB TOKEN → Apple CCID драйвер, SM APDU гээгдэнэ (eSign ажиллахгүй)
READER_PATTERN="ePass|FT.*Auto|HYPERSECU"

readers() {
  system_profiler SPSmartCardsDataType 2>/dev/null | sed -n '/Readers:/,/Reader Drivers:/p'
}

reader_active() {
  readers | grep -qiE "$READER_PATTERN"
}

if readers | grep -qi "HYPERSECU"; then
  echo "⚠️  Reader 'HYPERSECU USB TOKEN' нэрээр танигдсан — Apple-ийн CCID драйвер"
  echo "   барьж байгаа тул eSign ажиллахгүй. FeiTian драйверыг идэвхжүүлнэ үү:"
  echo ""
  echo "   sudo defaults write /Library/Preferences/com.apple.security.smartcard useIFDCCID -bool yes"
  echo ""
  echo "   Дараа нь токеноо салгаж дахин залгаад энэ script-ийг ажиллуулна уу."
elif reader_active; then
  echo "✅ Токен аль хэдийн идэвхтэй байна! eSign руугаа орж 'Дахин оролдох' дарна уу."
else
  # CD_ROM_Mode дээр байгаа HyperPKI диск олох
  DISK=$(diskutil list 2>/dev/null | grep -iE "CD_ROM.*HyperPKI|HyperPKI.*CD_ROM" | grep -oE "disk[0-9]+" | head -1)

  if [ -z "$DISK" ]; then
    echo "⚠️  Токен олдсонгүй. USB-д залгаатай эсэхээ шалгаад дахин ажиллуулна уу."
  else
    echo "📀 CD-ROM горим илрлээ ($DISK) — eject хийж байна..."
    diskutil eject "$DISK" >/dev/null 2>&1

    echo "⏳ CCID руу шилжихийг хүлээж байна..."
    for i in 1 2 3 4 5 6 7 8; do
      sleep 1
      if reader_active; then
        echo ""
        echo "✅ ТОКЕН ИДЭВХЖЛЭЭ! eSign программ руугаа орж 'Дахин оролдох' дарж PIN-ээ оруулна уу."
        break
      fi
      echo "   ...$i секунд"
    done
  fi
fi

echo ""
echo "(Энэ цонхыг хаахад асуудалгүй)"
