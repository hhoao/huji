import base64
import hashlib

from Crypto.Cipher import AES
from Crypto.Hash import SHA512
from Crypto.Protocol.KDF import PBKDF2
from Crypto.Util.Padding import pad, unpad


class Jasypt4py:
    def __init__(
        self,
        password: bytes,
        salt: str | bytes | None = None,
        iv: str | bytes | None = None,
        iterations: int = 1000,
    ) -> None:
        if salt is None:
            salt = self.secure_hash(password)
        if iv is None:
            iv = self.secure_hash(password)
        self.iv: bytes = iv.encode("utf-8") if isinstance(iv, str) else iv
        salt_bytes: bytes = salt.encode("utf-8") if isinstance(salt, str) else salt
        password_str: str = password.decode("utf-8")
        self.key: bytes = PBKDF2(
            password_str, salt_bytes, 32, count=iterations, hmac_hash_module=SHA512
        )

    def decrypt(self, encrypted: bytes) -> bytes:
        cipher = AES.new(self.key, AES.MODE_CBC, self.iv)  # type: ignore
        ct_bytes = base64.b64decode(encrypted)
        return unpad(cipher.decrypt(ct_bytes), AES.block_size)

    def encrypt(self, plaintext: bytes) -> str:
        cipher = AES.new(self.key, AES.MODE_CBC, self.iv)  # type: ignore
        ct_bytes = cipher.encrypt(pad(plaintext, AES.block_size))
        return base64.b64encode(ct_bytes).decode("utf-8")

    def secure_hash(self, text: bytes) -> bytes:
        return hashlib.sha256(text).hexdigest().encode("utf-8")
