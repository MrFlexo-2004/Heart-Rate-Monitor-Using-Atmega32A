import asyncio
from bleak import BleakClient

# ✅ Replace this with your Chest Strap BLE MAC address
MAC_ADDRESS = "xx:xx:xx:xx:xx:xx"
HR_UUID = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"  # Put the HR Measurement UUID

def handle_heart_rate(_, data):
    # First byte is flags, second (or second+third) is HR value
    hr_format = data[0] & 0x01
    if hr_format == 0:
        hr = data[1]
    else:
        hr = int.from_bytes(data[1:3], byteorder='little')
    print(f"❤️ Heart Rate: {hr} bpm")

async def main():
    async with BleakClient(MAC_ADDRESS) as client:
        if await client.is_connected():
            print(f"✅ Connected to {MAC_ADDRESS}")
            await client.start_notify(HR_UUID, handle_heart_rate)
            print("⏱️ Receiving heart rate data... Press Ctrl+C to stop.")
            while True:
                await asyncio.sleep(1)

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\n🛑 Stopped by user.")
