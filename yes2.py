from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
from cryptography.hazmat.primitives import hashes

def decrypt_message(encrypted_message, salt, iv, password):
    kdf = PBKDF2HMAC(
        algorithm=hashes.SHA256(),
        length=32,
        salt=salt,
        iterations=100000,
        backend=default_backend()
    )
    key = kdf.derive(password.encode())

    # Create a cipher object
    cipher = Cipher(algorithms.AES(key), modes.CFB(iv), backend=default_backend())
    decryptor = cipher.decryptor()

    # Decrypt the message
    decrypted_message = decryptor.update(encrypted_message) + decryptor.finalize()

    return decrypted_message

# Your provided data
encrypted_message = b'\xe6\xdbW\x080F\x13\x80\xd3\x18\t\xe7\xe1\x84\\\x1b\x91h\xe6\xces\x9e\xb3x\xf8\xc1\x7f\x02\xf1\xf3\xa2\xcc\xf5VSk\xbe'
salt = b'2\x8d\xf0\xbe\x06 \x07\xbb\xd9\x1c\x80\\\xfe\xc6\xfa{'
iv = b'\xd7\x92\xf3f\x1f\x8a\xfc\x11\x7f\xce\xf2m\x15M\x9fG'
password = 'porcica1'

# Decrypt the message
decrypted_message = decrypt_message(encrypted_message, salt, iv, password)

print(decrypted_message.decode('utf-8'))
