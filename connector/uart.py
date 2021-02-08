import serial

# Simple library class for handling UART
class Connection:
    def __init__(self, comPort):
        self._serialObject = None
        self._comPort = comPort
        try:
            self._serialObject = serial.Serial(self._comPort, 115200)
        except Exception as e:
            print(e)
        if self._serialObject is not None and self._serialObject.is_open:
            print('Successfully opened port ' + self._comPort + '\n')
        else:
            print('Failed to connect to ' + self._comPort + '\n')
            return False

    def readUInt8(self):
        while self._serialObject.in_waiting < 1:
            pass
        ret = int.from_bytes(self._serialObject.read(), 'little', signed=False) & 0xFF
        return ret

    def readUInt16(self):
        while self._serialObject.in_waiting < 2:
            pass
        bytes = self._serialObject.read(2)
        ret = int.from_bytes(bytes, 'little', signed=False) & 0xFFFF
        return ret

    def readUInt32(self):
        while self._serialObject.in_waiting < 4:
            pass
        bytes = self._serialObject.read(4)
        ret = int.from_bytes(bytes, 'little', signed=False) & 0xFFFFFFFF
        return ret

    def readUInt64(self):
        while self._serialObject.in_waiting < 8:
            pass
        bytes = self._serialObject.read(8)
        ret = int.from_bytes(bytes, 'little', signed=False) & 0xFFFFFFFFFFFFFFFF
        return ret
    def readBytes(self,l):
        while self._serialObject.in_waiting < l:
            pass
        return self._serialObject.read(l)
        
    def writeUInt8(self, value):
        bytes = value.to_bytes(1, 'little', signed=False)
        self._serialObject.write(bytes)
        self.flushOutput()

    def writeUInt16(self, value):
        bytes = value.to_bytes(2, 'little', signed=False)
        self._serialObject.write(bytes)

    def writeUInt32(self, value):
        bytes = value.to_bytes(4, 'little', signed=False)
        self._serialObject.write(bytes)

    def writeUInt64(self, value):
        bytes = value.to_bytes(8, 'little', signed=False)
        self._serialObject.write(bytes)

    def writeBytes(self, bytes):
        self._serialObject.write(bytes)

    def flushOutput(self):
        self._serialObject.flushOutput()

    def getIsConnected(self):
        return self._serialObject is not None and self._serialObject.is_open

