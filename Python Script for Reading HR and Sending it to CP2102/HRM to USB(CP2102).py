import asyncio
from bleak import BleakClient
import serial
import time

# Replace with your device's MAC address (case-sensitive)
MAGENE_MAC = "xx:xx:xx:xx:xx:xx"

# Put the HR Measurement UUID
HRM_UUID = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

# Serial port (check with: 'ls /dev/ttyUSB*') (for Linux in terminal) (Check with : 'COMX' ) (for windows in device manager)
SERIAL_PORT = "/dev/ttyUSBX"
BAUD_RATE = 9600

# Open serial connection to CP2102
serial_to_cp2102 = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=1)
time.sleep(2)  # Give CP2102 time to reset

def handle_hrm_data(sender, data):
    """Callback for handling HRM data from BLE"""
    hr = data[1]  # The second byte typically holds the heart rate
    print(f"Heart Rate: {hr} bpm")
    try:
        serial_to_cp2102.write(f"{hr}\n".encode())
    except Exception as e:
        print("Error writing to serial:", e)

async def main():
    print("Connecting to Magene H303...")
    async with BleakClient(MAGENE_MAC) as client:
        connected = await client.is_connected()
        print(f"Connected: {connected}")
        if not connected:
            return

        await client.start_notify(HRM_UUID, handle_hrm_data)
        print("Listening for heart rate data...")

        try:
            while True:
                await asyncio.sleep(1)
        except KeyboardInterrupt:
            print("Disconnecting...")
        finally:
            await client.stop_notify(HRM_UUID)
            serial_to_cp2102.close()

if __name__ == "__main__":
    asyncio.run(main())
