#!/usr/bin/env python3
"""eSign токены PKCS#11 түвшний оношлогоо (libcastle).

Хэрэглээ:
    python3 p11test.py [/usr/local/lib/libcastle_v2.1.0.0.dylib]

Хэвийн үед: GetTokenInfo=0x0, label=PKI eToken, сертификат уншигдана.
0x5 (CKR_GENERAL_ERROR) буцаавал Apple-ийн CCID драйвер SM APDU гээж байна —
README-гийн "Асуудал 2" (useIFDCCID fix)-ийг үз.
"""
import ctypes
import sys

DEFAULT_MODULE = "/usr/local/lib/libcastle_v2.1.0.0.dylib"
CKO_CERTIFICATE = 1
CKA_LABEL = 3
CKF_SERIAL_SESSION = 4


class Attr(ctypes.Structure):
    _fields_ = [
        ("type", ctypes.c_ulong),
        ("pValue", ctypes.c_void_p),
        ("len", ctypes.c_ulong),
    ]


def main() -> int:
    module = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_MODULE
    lib = ctypes.CDLL(module)
    print(f"module: {module}")
    print(f"C_Initialize: {hex(lib.C_Initialize(None))}")

    n = ctypes.c_ulong(0)
    rv = lib.C_GetSlotList(1, None, ctypes.byref(n))
    print(f"C_GetSlotList: {hex(rv)} (token present slots: {n.value})")
    if rv != 0 or n.value == 0:
        print("Токентой slot алга — токен залгаатай эсэхээ шалгана уу.")
        return 1

    slots = (ctypes.c_ulong * n.value)()
    lib.C_GetSlotList(1, slots, ctypes.byref(n))

    ok = True
    for slot in list(slots)[: n.value]:
        ti = (ctypes.c_char * 400)()
        rv = lib.C_GetTokenInfo(slot, ctypes.byref(ti))
        label = ti.raw[:32].rstrip(b"\x00 ").decode(errors="replace")
        print(f"slot {slot}: C_GetTokenInfo={hex(rv)} label={label!r}")
        if rv != 0:
            ok = False
            continue

        sess = ctypes.c_ulong(0)
        rv = lib.C_OpenSession(slot, CKF_SERIAL_SESSION, None, None, ctypes.byref(sess))
        print(f"slot {slot}: C_OpenSession={hex(rv)}")
        if rv != 0:
            ok = False
            continue

        cls = ctypes.c_ulong(CKO_CERTIFICATE)
        attr = Attr(0, ctypes.cast(ctypes.byref(cls), ctypes.c_void_p), ctypes.sizeof(cls))
        lib.C_FindObjectsInit(sess, ctypes.byref(attr), 1)
        objs = (ctypes.c_ulong * 10)()
        found = ctypes.c_ulong(0)
        lib.C_FindObjects(sess, objs, 10, ctypes.byref(found))
        lib.C_FindObjectsFinal(sess)
        print(f"slot {slot}: certificates={found.value}")
        for obj in list(objs)[: found.value]:
            buf = (ctypes.c_char * 256)()
            a = Attr(CKA_LABEL, ctypes.cast(ctypes.byref(buf), ctypes.c_void_p), 256)
            if lib.C_GetAttributeValue(sess, obj, ctypes.byref(a), 1) == 0:
                print(f"  cert: {buf.raw[:a.len].decode(errors='replace')}")
        lib.C_CloseSession(sess)

    lib.C_Finalize(None)
    if ok:
        print("\n✅ PKCS#11 бүрэн ажиллаж байна.")
    else:
        print("\n❌ CKR алдаа гарлаа — README 'Асуудал 2' (useIFDCCID) хэсгийг үз.")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
