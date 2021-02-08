import hashlib

# Calculates the SHA-256d message digest
# of a the given bytes.
def sha256_twice(header : bytes):
    m = hashlib.sha256()
    m2 = hashlib.sha256()
    
    m.update(header)
    pre_hash_value = m.digest()
    
    m2.update(pre_hash_value)
    return m2.digest().hex()


# Calculates the hash of a block based on the block
# header and the nonce (big-endian)
def bitcoinHash(header: bytes, nonce: str):
    return sha256_twice(header[:76] + convertByteEndianess(bytes.fromhex(nonce)))


# Same as bitcoinHash(), but increments the 
# timestamp if neccessary.    
def bitcoinHashWithTimeIncrement(header: bytes, nonce: str):
    timeIncremented = False
    hash = bitcoinHash(header, nonce)
 
    while (uintFromLittle(bytes.fromhex(hash)) > getTargetValue(header)):
        header = incrementTimestamp(header)
        timeIncremented = True
        hash = bitcoinHash(header, nonce)
    
    return hash, timeIncremented


def getTargetValue(header:bytes):
    return convertCompact(convertByteEndianess(header[72:76]))


def incrementTimestamp(header: bytes):
    return header[:68] + (uintFromLittle(header[68:72]) + 1).to_bytes(4, "little") + header[72:]


def convertCompact(compact: bytes):
    return uintFromBig(compact[1:] + (b'\x00' * (uintFromBig(compact[:1]) - 3)))


def uintFromBig(b: bytes):
    return int.from_bytes(b, "big", signed=False)


def uintFromLittle(b: bytes):
    return int.from_bytes(b, "little", signed=False)


def convertEndianess(h:str):
    return convertByteEndianess(bytes.fromhex(h)).hex()


def convertByteEndianess(h: bytes):
    return h[::-1]
    