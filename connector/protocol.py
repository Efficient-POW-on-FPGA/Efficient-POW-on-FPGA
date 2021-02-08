import uart

class Protocol:
    def __init__(self, conn):
        self.connection=conn
    
    def expectEnd(self):
        # expect single byte at end of reply
        self.connection.readUInt8()
    
    def sendHeader(self,payloadLen,replyPayloadLen,funcIdent):
        self.connection.writeUInt8(payloadLen)
        self.connection.writeUInt8(replyPayloadLen)
        self.connection.writeUInt8(funcIdent)

    #Sends some bytes to the FPGA.
    def writeMessage(self, bytes):
        self.sendHeader(len(bytes), 0 , 3)

        # send header bytes
        self.connection.writeBytes(bytes)

        self.expectEnd()

    # Reads the current processed nonce
    # and whether it leads to a valid hash.
    # 
    # Returns: found (boolean), nonce (big-endian)
    def readCurrentNonce(self):
        # length: found bit (1) + nonce bytes (4)
        self.sendHeader(0, 1 + 4 , 4)

        # read found bit
        found_byte = self.connection.readUInt8()

        # eveluate found bit
        found = found_byte == 1
        
        # reads 32 bit nonce
        nonce = self.connection.readBytes(4)
        
        self.expectEnd()

        return found, nonce.hex() 