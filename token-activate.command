#!/bin/bash
# eSign токен (FeiTian HyperPKI / ePass2003Auto) идэвхжүүлэгч
# Токен залгахад CD-ROM горимд гацдаг тул CD-г eject хийж CCID руу шилжүүлнэ.

echo "🔑 eSign токен идэвхжүүлж байна..."
echo ""

# Reader нэр нь "FT ePass2003Auto" эсвэл "HYPERSECU USB TOKEN" гэж танигддаг
READER_PATTERN="ePass|FT.*Auto|HYPERSECU"

reader_active() {
  system_profiler SPSmartCardsDataType 2>/dev/null | grep -qiE "$READER_PATTERN"
}

# Mode 2 үед CD mount-тай атлаа reader аль хэдийн идэвхтэй байдаг тул
# эхлээд reader-ийг шалгана — идэвхтэй бол eject хийх шаардлагагүй.
if reader_active; then
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
