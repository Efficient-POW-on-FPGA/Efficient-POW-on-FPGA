import os
import time
class Connection:
    def __init__(self, readpipe_,writepipe_):
        self.writepipe =os.open(writepipe_,os.O_WRONLY)
        self.readpipe = os.open(readpipe_,os.O_RDONLY|os.O_NONBLOCK)
        os.set_blocking(self.readpipe,1)

    def readBytes(self, num):
        res=b''
        remaining=num
        while remaining>0:
            part=os.read(self.readpipe,remaining)
            res+=part
            remaining-=len(part)
        return res

    def readUInt8(self):
        ret = int.from_bytes(self.readBytes(1), 'little', signed=False) & 0xFF
        return ret

    def readUInt16(self):
        ret = int.from_bytes(self.readBytes(2), 'little', signed=False) & 0xFFFF
        return ret

    def readUInt32(self):
        ret = int.from_bytes(self.readBytes(4), 'little', signed=False) & 0xFFFFFFFF
        return ret

    def readUInt64(self):
        ret = int.from_bytes(self.readBytes(8), 'little', signed=False) & 0xFFFFFFFFFFFFFFFF
        return ret

    def writeUInt8(self, value):
        bytes = value.to_bytes(1, 'little', signed=False)
        os.write(self.writepipe,bytes)

    def writeUInt16(self, value):
        bytes = value.to_bytes(2, 'little', signed=False)
        os.write(self.writepipe,bytes)

    def writeUInt32(self, value):
        bytes = value.to_bytes(4, 'little', signed=False)
        os.write(self.writepipe,bytes)

    def writeUInt64(self, value):
        bytes = value.to_bytes(8, 'little', signed=False)
        os.write(self.writepipe,bytes)

    def writeBytes(self, bytes):
        os.write(self.writepipe,bytes)


