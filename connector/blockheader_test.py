# Larger test to check if correct nonces for many blockheaders (read from file) can be found

import uart
import protocol
import sys
import time
import random

def extractNonce(header):
    return header[152:]

# read blockheaders with correct nonces from blockheaders.txt file
with open('../sim/blockheaders.txt') as f:
    block_headers = [line.rstrip() for line in f]

connection =  uart.Connection("/dev/ttyUSB2")

protocol = protocol.Protocol(connection)

for header in block_headers:

    expected_nonce = extractNonce(header)

    # substract a random number from nonce
    # recreate header with the new nonce
    start_nonce = int(extractNonce(header), 16) - random.randint(200,10000);
    if(start_nonce < 0):
        start_nonce = 0
    header = header[:152] + '{:08x}'.format(start_nonce)
    
    protocol.writeMessage(0, bytes.fromhex(header))

    found, nonce = protocol.readCurrentNonce()
    hash = util.sha256_twice(header[:76] + bytes.fromhex(nonce))
    
    print(str(found) +" "+ hash +" "+ nonce)
    
    if not found:
        raise Exception("Could not find a valid nonce for a given header! \n Expected Nonce: {} \n Used Header: {}".format(expected_nonce, header))

    if not nonce == expected_nonce:
        raise Exception("Could find nonce but not, this is not the same as in the bitcoin chain. \n Expected Nonce: {} \n Actual Nonce: {} \n Used Header: {}".format(expected_nonce, nonce, header))

