# KDBX

This package is meant to serve as an interface to the kdbx file format from Keepass.

With it you can read from the kdbx file format and save the the kdbx file format. (With encryption)

This package uses a combination of the ChaCha20 Stream Cipher and AES256 Encryption to encrypt and decrypt the file.

## Sources

Thanks in large part to the following people for documenting the kdbx file format:

Wladimir Palant
[Documenting KeePass KDBX4 file format](https://palant.info/2023/03/29/documenting-keepass-kdbx4-file-format/)

Zaur Molotnikov
[KeePassXC Application Security Review](https://keepassxc.org/assets/pdf/KeePassXC-Review-V1-Molotnikov.pdf)
