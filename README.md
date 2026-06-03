# cia-unix

*Decrypt CIA and 3DS roms in UNIX and PowerShell environments (Linux, Windows and MacOS)*

```
cia-unix/
├─ bin/
│  ├─ Linux/
│  │  ├─ ctrdecrypt
│  │  ├─ ctrtool
│  │  ├─ makerom
│  ├─ MacOS/
│  │  ├─ arm64/
│  │  │  ├─ ctrtool
│  │  │  ├─ makerom
│  │  ├─ universal/
│  │  │  ├─ ctrdecrypt
│  │  ├─ x64/
│  │  │  ├─ ctrtool
│  │  │  ├─ makerom
│  ├─ Windows/
│  │  ├─ ctrdecrypt.exe
│  │  ├─ ctrtool.exe
│  │  ├─ makerom.exe
├─ cia-unix.sh
├─ cia-windows.ps1
├─ dlc.cia
├─ game.3ds
├─ game.cia
├─ seeddb.bin
└─ update.cia
```

## ✅ Roadmap
- [x] Decrypt .cia
  - [x] Games
  - [x] Updates and DLCs
- [x] Decrypt .3ds
- [x] Rust [`decrypt.py`](https://github.com/shijimasoft/cia-unix/blob/old-python3/decrypt.py) rewrite (ctrdecrypt)
- [x] Port [`cia-unix.cr`](https://github.com/shijimasoft/cia-unix/blob/main/cia-unix.cr) to cia-unix.sh and cia-windows.ps1


> [!WARNING]
> Decryption with cia-unix may fail, when it happens it is suggested to decrypt roms directly on the 3DS.

The old _python 3_ version can be found [here](https://github.com/shijimasoft/cia-unix/tree/old-python3).

## Windows users

You need to run this command in PowerShell before running .\cia-windows.ps1:

Set-ExecutionPolicy -Scope Process Bypass

## Contributors
ctrtool and makerom are from [3DSGuy repository](https://github.com/3DSGuy/Project_CTR)

ctrdecrypt are from [shijimasoft repository](https://github.com/shijimasoft/ctrdecrypt)

seeddb.bin are from [ihaveamac repository](https://github.com/ihaveamac/3DS-rom-tools)

*Adaware* contributed translating the [windows-only version](https://github.com/matiffeder/3DS-stuff/blob/master/Batch%20CIA%203DS%20Decryptor.bat)
