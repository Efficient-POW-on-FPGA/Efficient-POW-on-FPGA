# Test for checking whether serveral headers for all modulo rest can be found:

import uart
import simulation
import protocol
import util
import sys
import os
import time

def extractNonce(header):
    return hex(int.from_bytes(bytes.fromhex(header)[-4:],"little"))[2:].zfill(8)

#Time necessary for calculating the nonce
#(has to be longer for the simulation)
waiting_period = 5

#Read block header from file

block_headers = []

f = open("test/header", "r")

for line in f:
    block_headers.append(line.rstrip("\n"))

# Set up connection to specified target

if len(sys.argv) != 2:
    raise Exception("Expected exactly one argument specifing the test target [simulation|fpga]!")

target = sys.argv[1]

if target == "simulation":
    print("Connect to simulation!")
    connection = simulation.Connection("build/pipe.out", "build/pipe.in")
    print("Successfully connected!")

elif target == "fpga":
    waiting_period = 1

    device = os.getenv("DEVICE", "/dev/ttyUSB2")
    print("Connection to " + device+"!")
    connection =  uart.Connection(device)
    print("Successfully connected!")

else:
    raise Exception("Target was {} but must be one of [simulation, fpga]!"
                        .format(target))

protocol = protocol.Protocol(connection)

# Send serveral Block headers and check for correct found nonce

i = 0

for header in block_headers:

    header_bytes = bytes.fromhex(header)

    # Decrement the nonce by the number of headers already done.
    # => Get different modulo rest => test all cores
    nonce_to_send = int.from_bytes(header_bytes[-4:],"little")
    nonce_to_send -= i
    i+=1

    #Put the new nonce and the header together and send it to the miner
    header_bytes = header_bytes[:-4] + nonce_to_send.to_bytes(4,"little")
    protocol.writeMessage(header_bytes)

    #Let the miner calculate
    time.sleep(waiting_period)

    found, nonce = protocol.readCurrentNonce()
    
    #Calculate Blockhash based on result
    hash = util.bitcoinHash(header_bytes, nonce)

    expected_nonce = extractNonce(header)

    if not found:
        raise Exception(("Could not find a valid nonce for a given header!\n" 
                        + "Expected Nonce: {}"  
                        + "\n Used Header (with decremented nonce): {}")
                            .format(expected_nonce, header_bytes.hex()))

    if not nonce == expected_nonce:
        raise Exception(("Could find nonce, but this is not the same as in the bitcoin chain. \n" + 
                        "Expected Nonce: {} \n" +
                        "Actual Nonce: {} \n" +
                        "Used Header (with decremented nonce): {}")
                            .format(expected_nonce, nonce, header_bytes.hex()))

    print("Successfully calculated hash: {} nonce: {} offset: {}"
            .format(hash, nonce, i-1), flush=True)



# Test the timestamp addition (only on FPGA, as waiting ~180 seconds per header is too long for simulation)

if target == "fpga":

    # First header tests timestamp increment with a start nonce that causes an unsigned overflow, 
    # second tests timestamp increment without unsigned overflow
    headers = ["02000000e18d2da1f7a2bf490d0c803ebfeb03dd2bfb1dfa6a86b31b00000000000000005e590801733042d6c3f5f264693d068bdfbebe23bc6c7c7c813264ba18cf2252f2ea3f5473691f1800000000",
               "02000000e18d2da1f7a2bf490d0c803ebfeb03dd2bfb1dfa6a86b31b00000000000000005e590801733042d6c3f5f264693d068bdfbebe23bc6c7c7c813264ba18cf2252f2ea3f5473691f1884e0d3d0" ]


    i  = 1

    for header in headers:

        header_bytes = bytes.fromhex(header)

        protocol.writeMessage(header_bytes)

        # Sleep a while, as going over all nonces takes a while
        time.sleep(250)

        found, nonce = protocol.readCurrentNonce()

        expected_nonce = 'd0d3e084'
        
        if not found:
            raise Exception(("Could not find a valid nonce for a given header!\n" 
                        + "Expected Nonce: {}"  
                        + "\n Used Header (with decremented nonce): {}")
                            .format(expected_nonce, header_bytes.hex()))

        if not nonce == expected_nonce:
            raise Exception(("Could find nonce, but this is not the same as in the bitcoin chain. \n" + 
                        "Expected Nonce: {} \n" +
                        "Actual Nonce: {} \n" +
                        "Used Header (with decremented nonce): {}")
                            .format(expected_nonce, nonce, header_bytes.hex()))

        print("Successfully calculated hash with decremented timestamp number {} of \n".format(i), flush=True)
