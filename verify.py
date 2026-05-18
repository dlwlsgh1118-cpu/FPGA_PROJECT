from Crypto.Cipher import AES

class AES_CTR_Sync:
    def __init__(self, key_hex, nonce_hex):
        self.key   = bytes.fromhex(key_hex)
        self.nonce = bytes.fromhex(nonce_hex)
        self.ctr   = 0

    def encrypt(self, plaintext_int):
        aes_input  = self.nonce + self.ctr.to_bytes(8, byteorder='big')
        cipher     = AES.new(self.key, AES.MODE_ECB)
        keystream  = cipher.encrypt(aes_input)
        plaintext  = plaintext_int.to_bytes(16, byteorder='big')
        ciphertext = bytes(a ^ b for a, b in zip(plaintext, keystream))
        self.ctr  += 1
        return ciphertext

    def decrypt(self, ciphertext_bytes):
        aes_input = self.nonce + self.ctr.to_bytes(8, byteorder='big')
        cipher    = AES.new(self.key, AES.MODE_ECB)
        keystream = cipher.encrypt(aes_input)
        plaintext = bytes(a ^ b for a, b in zip(ciphertext_bytes, keystream))
        self.ctr += 1
        return plaintext

    def reset_ctr(self):
        self.ctr = 0


# 검증
aes = AES_CTR_Sync(
    key_hex   = "000102030405060708090a0b0c0d0e0f",
    nonce_hex = "deadbeefdeadbeef"
)

c0 = aes.encrypt(1234)
print(f"암호문:  {c0.hex()}")
print(f"기대값:  b876aff70a8c706999511b08ad62d5b4")
print(f"일치:    {c0.hex() == 'b876aff70a8c706999511b08ad62d5b4'}")

aes.reset_ctr()
p0 = aes.decrypt(c0)
print(f"복호화:  {int.from_bytes(p0, 'big')}")
print(f"기대값:  1234")
