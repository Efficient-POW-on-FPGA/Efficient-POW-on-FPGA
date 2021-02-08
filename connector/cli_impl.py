import protocol
import uart
import simulation
import util
import time
import os

# Headers for testing
default_header = "00000020a9d3e619c61beb426d951c77cf09d6d7a95d8471ef8604000000000000000000c2ee46bca5d44b999df0b008e920df68b235d9baa7f77fbfec99f88e86e248035817ac5e33a31117c850a5b4"
wrong_header = "00000010a9d3e619c61beb426d951c77cf09d6d7a95d8471ef8604000000000000000000c2ee46bca5d44b999df0b008e920df68b235d9baa7f77fbfec99f88e86e248035817ac5e33a3111700000010"

# Set up connection to sim or the FPGA
def getProtocol(use_sim):
    if use_sim:
        print("\n##### Connecting to simulation #####\n")
        connection = simulation.Connection("build/pipe.out", "build/pipe.in")
    else:
        print("\n##### Connecting to FPGA: #####\n")
        #Correct port can be set as env.
        device = os.getenv("DEVICE", "/dev/ttyUSB2")
        connection = uart.Connection(device)

    return protocol.Protocol(connection)

# Send block header
def mine(protocol, header, follow):
    # Get bytes from a hex string
    byte_header = bytes.fromhex(header)

    # If no nonce is provided we pad with zeros
    if len(byte_header) == 76:
        byte_header = byte_header + b'\x00\x00\x00\x00'

    # Check if the length is correct (80 * 4 bit = 640 bit)
    if len(byte_header) != 80:
        raise Exception("Block header length must be 608 or 640 bit!, but has %s bit!" % (
            len(byte_header) * 8))

    # Send header to FPGA/Simulation
    print("##### Sending header #####\n\nHeader: " + byte_header.hex() + "\n")
    protocol.writeMessage(byte_header)
    print("Sending succeeded\n")

    # Wait for result
    if (follow):
        found, nonce = readResult(protocol, follow)
        hash, _ = util.bitcoinHashWithTimeIncrement(byte_header, nonce)
        print(
            "\n             You successfully mined a             \n",
            "██████╗ ██╗████████╗ ██████╗ ██████╗ ██╗███╗   ██╗\n",
            "██╔══██╗██║╚══██╔══╝██╔════╝██╔═══██╗██║████╗  ██║\n",
            "██████╔╝██║   ██║   ██║     ██║   ██║██║██╔██╗ ██║\n",
            "██╔══██╗██║   ██║   ██║     ██║   ██║██║██║╚██╗██║\n",
            "██████╔╝██║   ██║   ╚██████╗╚██████╔╝██║██║ ╚████║\n",
            "╚═════╝ ╚═╝   ╚═╝    ╚═════╝ ╚═════╝ ╚═╝╚═╝  ╚═══╝\n",
            "                     Block                        \n")
        print("Blockhash: " + hash + "\n")
        
# Send a header with a correct nonce
def sendTestHeader(protocol, follow):
    mine(protocol, default_header, follow)


# Read hash, nonce and found (once or repeated until a block is found)
def readResult(protocol, repeated=False):
    print("##### Start reading values from FPGA #####\n")
    print("Hash found\t| Nonce ")
    print("--------------- | ------")

    found = False
    repeat = True

    while(repeat):
        # Read values
        found, nonce = protocol.readCurrentNonce()
        print(found, "\t\t| ", util.convertEndianess(nonce))

        # Needed since there is no do while in python
        if (not repeated) or found:
            repeat = False

    return found, nonce


# Count number of hashes calculated in a certain period
def count(protocol):
    # Send header that should lead to no correct block
    mine(protocol, wrong_header, False)

    print("##### Counting #####\n")

    # Save first nonce
    _, start_nonce = protocol.readCurrentNonce()
    start = int("0x" + start_nonce, 0)

    # Wait for some seconds
    duration = 10
    for i in range(duration):
        print("[" + i * "#" + (duration - i) * " " + "] " +
              str((i / duration * 100)) + "%", end="\r")
        time.sleep(1)

    # Save end nonce
    found, end_nonce = protocol.readCurrentNonce()
    end = int("0x" + end_nonce, 0)
    print("Finished counting \n ")

    # Calculate stats
    diff = end - start
    rate = diff / duration

    print(("##### Statistic #####\n\n"
           + "First nonce: {}\n"
           + "Last nonce: {}\n"
           + "Duration: {} sec\n"
           + "Total blockhash number: {}\n"
           + "Avg blockhash-rate: {} Blockhashes/second").format(start_nonce, end_nonce, duration, diff, rate))
