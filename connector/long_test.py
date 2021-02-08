# Test for checking whether serveral headers for all modulo rest can be found:

import uart
import simulation
import protocol
import util
import sys
import os
import time
import random

random.seed(42)

def extractNonce(header):
    return hex(int.from_bytes(bytes.fromhex(header)[-4:],"little"))[2:].zfill(8)

#Time necessary for calculating the nonce
#(has to be longer for the simulation)
waiting_period = 5

#Read block header from file

block_headers = []

f = open("test/header_long", "r")

for line in f:
    block_headers.append(line.rstrip("\n"))

# Set up connection to specified target

device = os.getenv("DEVICE", "/dev/ttyUSB2")
print("Connection to " + device+"!")
connection =  uart.Connection(device)
print("Successfully connected!")

protocol = protocol.Protocol(connection)

# Send serveral Block headers and check for correct found nonce

for header in block_headers:

    header_bytes = bytes.fromhex(header)

    # Decrement the nonce by the number of headers already done.
    # => Get different modulo rest => test all cores
    nonce_to_send = int.from_bytes(header_bytes[-4:],"little")
    nonce_to_send = random.randint(0, nonce_to_send)

    #Put the new nonce and the header together and send it to the miner
    header_bytes = header_bytes[:-4] + nonce_to_send.to_bytes(4,"little")
    protocol.writeMessage(header_bytes)

    #Let the miner calculate (for at most 100 s)
    start_time = int(time.time())

    found = False
    nonce = ""
    isTimeOut = False

    while not found: 
        found, nonce = protocol.readCurrentNonce()

        isTimeout = int(time.time()) - start_time > 100 
        if (isTimeout):
            print("TIMEOUT for header: "+ header_bytes.hex())
            break
        time.sleep(3)

    if (isTimeOut):
        continue

    #Calculate Blockhash based on result
    hash = util.bitcoinHash(header_bytes, nonce)

    expected_nonce = extractNonce(header)

    if not found:
        print(("Could not find a valid nonce for a given header!\n" 
                        + "Expected Nonce: {}"  
                        + "\n Used Header (with decremented nonce): {}")
                            .format(expected_nonce, header_bytes.hex()))
        continue

    if not nonce == expected_nonce:
        print(("Could find nonce, but this is not the same as in the bitcoin chain. \n" + 
                        "Expected Nonce: {} \n" +
                        "Actual Nonce: {} \n" +
                        "Used Header (with decremented nonce): {}")
                            .format(expected_nonce, nonce, header_bytes.hex()))
        continue 

    print("Successfully calculated hash: {} nonce: {} start nonce: {}"
            .format(hash, nonce, nonce_to_send), flush=True)
