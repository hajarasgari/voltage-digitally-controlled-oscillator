# ref: https://docs.micropython.org/en/latest/library/pyb.ADC.html
import pyb
led = pyb.LED(1)
led.on()
pin = pyb.Pin(pyb.Pin.cpu.A2, pyb.Pin.ANALOG)
cs = pyb.Pin(pyb.Pin.cpu.C2, pyb.Pin.OUT)
adc = pyb.ADC(pin)           # create an analog object from a pin
spi = pyb.SPI(2, pyb.SPI.MASTER, baudrate=400000, bits=16, polarity=1, phase=0, crc=0x7)
cs.value(1)
while True:
  led.toggle()
  val = adc.read()                    # read an analog value
  print(val)
  cs.value(0)
  spi.send(val)
  cs.value(1)
  pyb.delay(1000)