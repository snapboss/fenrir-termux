#!/data/data/com.termux/files/usr/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

DEVICE="${1:-pacman}"
DEVICE_LOWER=$(echo "$DEVICE" | tr '[:upper:]' '[:lower:]')

if [ -n "$2" ]; then
    BOOTLOADER="$2"
else
    BOOTLOADER="bin/${DEVICE_LOWER}.bin"
fi

if [ ! -f "$BOOTLOADER" ]; then
   echo -e "${RED}Error: Bootloader file '$BOOTLOADER' not found${NC}"
   exit 1
fi

echo
echo -e "${BOLD}Building for device: ${BLUE}$DEVICE${NC}"
echo -e "${BOLD}Bootloader: ${BLUE}$BOOTLOADER${NC}"
echo

rm -f *.patched
rm -rf payload/build

echo -e "${YELLOW}Building payload...${NC}"

(cd payload && make clean && make \
    CC="clang -target aarch64-none-elf" \
    AS="clang -target aarch64-none-elf" \
    LD="ld.lld" \
    OBJCOPY="llvm-objcopy" \
    OBJDUMP="llvm-objdump" \
    CROSS_COMPILE="" \
    DEVICE="$DEVICE" all -j$(nproc))

if [ $? -ne 0 ]; then
   echo -e "${YELLOW}Warning: Payload build failed or skipped. Continuing with patches only...${NC}"
fi

echo
echo -e "${YELLOW}Injecting payload...${NC}"
bash inject.sh "$DEVICE" "$BOOTLOADER"

echo

if [ -f "${DEVICE_LOWER}-fenrir.bin" ]; then
   echo -e "${GREEN}Operation completed successfully!${NC}"
   echo -e "${NC}Patched bootloader saved as: ${BOLD}${DEVICE_LOWER}-fenrir.bin${NC}"
else
    echo -e "${RED}Injection failed or output file not found!${NC}"
    exit 1
fi
