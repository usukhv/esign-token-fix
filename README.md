# eSign Token Fix (macOS)

FeiTian **HyperPKI / ePass2003Auto** цахим гарын үсгийн USB токеныг macOS дээр
ажиллуулах үед гарсан асуудал ба түүний шийдлийн дэлгэрэнгүй баримт.

> Богино тайлбар: Токен USB-д залгахдаа **CD-ROM горим**д гацдаг тул macOS түүнийг
> smart card (CCID) reader болгож танихгүй. Шийдэл нь виртуал CD-г **eject** хийж,
> **дахин залгахгүйгээр** хүлээх — ингэхэд firmware өөрөө CCID горим руу шилждэг.

---

## Агуулга

- [Асуудал](#асуудал)
- [Орчин](#орчин)
- [Шинж тэмдэг](#шинж-тэмдэг)
- [Үндсэн шалтгаан](#үндсэн-шалтгаан)
- [Оношлох алхмууд](#оношлох-алхмууд)
- [Шийдэл](#шийдэл)
- [Автомат script](#автомат-script)
- [Анхааруулга ба санамж](#анхааруулга-ба-санамж)
- [Холбоотой команд reference](#холбоотой-команд-reference)

---

## Асуудал

Цахим гарын үсгийн (eSign) программ нь токеныг хүлээж, дараах мессеж гаргана:

> **"Токен төхөөрөмжөө залгана уу"**

USB токеноо залгасан ч программ түүнийг олж харахгүй. macOS-ийн smart card
систем (`pcsc`) дээр reader **хоосон** байна:

```
Readers:
        ← хоосон, ямар ч reader танигдаагүй
```

Үүний өмнө татаж авсан `esign-installer.pkg` суулгахад Gatekeeper
*"Apple could not verify ... free of malware"* гэж блоклосон (энэ нь интернетээс
татсан файлд тавьдаг хэвийн quarantine — доорх [санамж](#анхааруулга-ба-санамж)-аас үз).

---

## Орчин

| Зүйл | Утга |
|------|------|
| OS | macOS (Darwin 25.x / Apple Silicon) |
| Токен | FeiTian **HyperPKI** (`HyperPKI_220712`), reader нэр: `FT ePass2003Auto` эсвэл `HYPERSECU USB TOKEN` |
| Драйвер | `HYPSmartToken.app`, `FTSmartToken.app` (`/Applications/`) |
| CCID bundle | `/usr/local/libexec/SmartCardServices/drivers/ifd-FeiTccid.bundle` |
| Daemon | `com.FTSmartCard.ePass2003.tokenservice` (ажиллаж байсан) |

---

## Шинж тэмдэг

1. Токен USB-д залгаатай атлаа eSign программ "залгана уу" гэсээр байна.
2. `system_profiler SPSmartCardsDataType` дээр `Readers:` хэсэг **хоосон**.
3. `diskutil list` дээр токен нь **CD-ROM** болж харагдана:

   ```
   /dev/disk4 (external, physical):
      0:   CD_partition_scheme              *159.0 MB   disk4
      1:   CD_ROM_Mode_1 HyperPKI_220712     138.4 MB   disk4s0
   ```

4. Драйвер бүгд суусан, daemon ажиллаж байгаа ч reader танигдахгүй.

---

## Үндсэн шалтгаан

FeiTian HyperPKI / ePass2003**Auto** токен нь firmware-ийн 3 горимтой:

| Горим | Тайлбар | Үр дүн |
|-------|---------|--------|
| `Mode 0` | Зөвхөн **CCID** (smart card) | ✅ Хэрэгтэй нь энэ |
| `Mode 1` | Зөвхөн **CD-ROM** (драйвер суулгагч) | ❌ Энэ дээр гацсан |
| `Mode 2` | CD-ROM + CCID хоёул | ✅ Бас болно |

> 💡 **Mode 2 ажиглалт:** Токен заримдаа CD-ROM mount-тай атлаа reader нь
> зэрэгцээ идэвхтэй байдаг (`HYPERSECU USB TOKEN` нэрээр, ATR-тай). Энэ үед
> eject хийх **шаардлагагүй** — шууд eSign дээр "Дахин оролдох" дарахад болно.
> Тиймээс script эхлээд reader-ийг шалгаж, идэвхтэй бол CD-д огт хүрэхгүй.

Токен залгахад **эхлээд CD-ROM (`CD_ROM_Mode_1`) болж** гарч ирдэг — энэ нь
Windows дээр драйверээ autorun-аар суулгуулах зорилготой. macOS дээр энэ нь
автоматаар CCID руу шилждэггүй тул токен **smart card reader болж танигддаггүй**.

CD доторх файлууд бүгд **Windows-only**:

```
autorun.exe
autorun.inf
HyperPKI_ePass2003_Setup.exe
```

→ macOS-д зориулсан mode-switch tool CD дотор **байхгүй**.

---

## Оношлох алхмууд

```bash
# 1. Smart card reader-ийн төлөв (хоосон бол асуудалтай)
system_profiler SPSmartCardsDataType | sed -n '/Readers:/,/Reader Drivers:/p'

# 2. Токен CD-ROM горимд байгаа эсэх
diskutil list | grep -iE "CD_ROM|HyperPKI"

# 3. Драйвер суусан эсэх
ls -d /Applications/HYPSmartToken.app /Applications/FTSmartToken.app

# 4. Token service daemon ажиллаж байгаа эсэх
launchctl list | grep -iE "ftsafe|ePass2003|hyp"
```

---

## Шийдэл

**Гол санаа:** Виртуал CD-г eject хийгээд, **токеноо дахин ЗАЛГАХГҮЙГЭЭР** хэдэн
секунд хүлээх. Ингэхэд firmware өөрөө CCID горим руу re-enumerate хийнэ.

```bash
# CD_ROM горим дээрх дискийг олох (ихэвчлэн disk4)
diskutil list | grep -iE "CD_ROM.*HyperPKI"

# eject хийх
diskutil eject disk4

# 5 секунд хүлээгээд reader танигдсан эсэхийг шалгах
system_profiler SPSmartCardsDataType | sed -n '/Readers:/,/Reader Drivers:/p'
```

Амжилттай бол:

```
Readers:
   #01: FT ePass2003Auto (ATR:{length = 23, bytes = 0x3b9f9581...})
```

`ATR` гарч ирвэл macOS токены чипийг бүрэн уншиж байна гэсэн үг.

> ⚠️ **Хамгийн чухал нюанс:** eject хийсний дараа токеноо **салгаад дахин
> залгавал** дахин CD-ROM горим руу буцна. Тиймээс eject хийсний дараа
> **зүгээр л хүлээ** — салгаж залгах хэрэггүй.

Reader танигдсаны дараа:

1. eSign программ руугаа буц
2. **"Дахин оролдох" / "Retry"** дар
3. Токены **PIN** оруул

---

## Автомат script

Токен залгах болгонд гар аргаар команд бичихгүйн тулд Desktop дээр
давхар дарж ажиллуулдаг `.command` файл хийсэн.

`Token-Идэвхжүүлэх.command`:

```bash
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
```

### Суулгах

```bash
# Desktop дээр хийгээд гүйцэтгэх эрх өгөх
chmod +x ~/Desktop/Token-Идэвхжүүлэх.command
```

### Ашиглах

1. Токеноо USB-д залга
2. Desktop дээрх **`Token-Идэвхжүүлэх`** дээр **давхар дар**
3. *"✅ ТОКЕН ИДЭВХЖЛЭЭ"* гарахыг хүлээ
4. eSign дээрээ **"Дахин оролдох"** → **PIN** оруул

> Анх давхар дарахад macOS *"баталгаажаагүй хөгжүүлэгч"* гэж блоклож магадгүй.
> Тэр үед: файл дээр **баруун товч → Open → Open** (нэг удаа). Дараа нь чөлөөтэй ажиллана.

---

## Анхааруулга ба санамж

### Gatekeeper (`esign-installer.pkg` блоклогдсон тухай)

Интернетээс татсан `.pkg` файлд macOS `com.apple.quarantine` тэмдэглэгээ тавьдаг.
Apple-аар баталгаажаагүй бол:

- **Баруун товч → Open → Open**, эсвэл
- **System Settings → Privacy & Security → Open Anyway**, эсвэл
- `xattr -d com.apple.quarantine ~/Downloads/esign-installer.pkg`

⚠️ Энэ нь *"энэ файлд итгэж байна"* гэсэн үг — зөвхөн **итгэлтэй албан ёсны
эх сурвалжаас** татсан бол үргэлжлүүл.

### Certificate / Token санамж

- Цахим гарын үсэг ажиллахын тулд итгэмжлэгдсэн **certificate** суулгах нь хэвийн.
- Гэхдээ танихгүй **root certificate**-ийг системд trust болгох нь аюулгүй
  байдлын эрсдэлтэй — зөвхөн албан ёсны eSign үйлчилгээ үзүүлэгчийн зааврыг дага.

### Хэрэв reader танигдахгүй хэвээр бол

1. Токеноо **шууд** Mac-д залга (hub/adapter биш)
2. Өөр USB порт туршаад үз
3. Драйвер (`HYPSmartToken.app`) суусан эсэхийг шалга
4. Mac-аа **restart** хийж, токеноо залгасан үед ачаалуул

---

## Холбоотой команд reference

| Зорилго | Команд |
|---------|--------|
| Reader жагсаалт | `system_profiler SPSmartCardsDataType` |
| Токен CD горимд эсэх | `diskutil list \| grep CD_ROM` |
| CD eject | `diskutil eject disk4` |
| pcsc тест | `pcsctest` |
| USB төхөөрөмж | `system_profiler SPUSBDataType` |
| Daemon шалгах | `launchctl list \| grep ftsafe` |
| Quarantine арилгах | `xattr -d com.apple.quarantine <file>` |

---

*Энэ баримт нь FeiTian HyperPKI / ePass2003Auto токеныг macOS дээр идэвхжүүлэх
бодит асуудлыг оношилж шийдсэн тэмдэглэл дээр үндэслэв.*
