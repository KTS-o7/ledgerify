#!/bin/bash

# Ledgerify Development Script
# Launches Android emulator and runs the app with hot reload
#
# Usage: ./scripts/run_dev.sh
#
# Requirements:
# - Flutter SDK installed and in PATH
# - Android SDK installed
# - At least one Android emulator configured

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Ledgerify Development Runner${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if flutter is installed
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}Error: Flutter is not installed or not in PATH${NC}"
    exit 1
fi

# Get emulator ID (first Android emulator found)
echo -e "${YELLOW}Checking available emulators...${NC}"
EMULATOR_ID=$(flutter emulators 2>/dev/null | grep "android" | head -1 | cut -d'•' -f1 | xargs)

if [ -z "$EMULATOR_ID" ]; then
    echo -e "${RED}No Android emulators found. Please create one using Android Studio.${NC}"
    echo -e "${YELLOW}Run: flutter emulators --create --name dev_phone${NC}"
    exit 1
fi

echo -e "${GREEN}Found emulator: ${EMULATOR_ID}${NC}"

# Check if emulator is already running
echo -e "${YELLOW}Checking for running devices...${NC}"
RUNNING_DEVICE=$(flutter devices 2>/dev/null | grep -i "emulator-" | head -n 1 || true)

if [ -n "$RUNNING_DEVICE" ]; then
    echo -e "${GREEN}Emulator already running!${NC}"
    echo "$RUNNING_DEVICE"
else
    # Launch emulator
    echo -e "${YELLOW}Launching emulator: ${EMULATOR_ID}${NC}"
    flutter emulators --launch "$EMULATOR_ID" &
    
    # Wait for emulator to boot
    echo -e "${YELLOW}Waiting for emulator to boot (this may take 30-60 seconds)...${NC}"
    
    COUNTER=0
    MAX_WAIT=90
    while [ $COUNTER -lt $MAX_WAIT ]; do
        DEVICE_READY=$(flutter devices 2>/dev/null | grep -i "emulator-" || true)
        if [ -n "$DEVICE_READY" ]; then
            echo ""
            echo -e "${GREEN}Emulator is ready!${NC}"
            echo "$DEVICE_READY"
            break
        fi
        sleep 2
        COUNTER=$((COUNTER + 2))
        echo -ne "\r${YELLOW}Waiting... ${COUNTER}s${NC}  "
    done
    
    if [ $COUNTER -ge $MAX_WAIT ]; then
        echo ""
        echo -e "${RED}Timeout waiting for emulator to boot${NC}"
        exit 1
    fi
fi

# Small delay to ensure emulator is fully ready
sleep 2

# Run flutter app with hot reload
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}Starting Ledgerify with hot reload...${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${YELLOW}Hot Reload Commands:${NC}"
echo -e "  ${GREEN}r${NC}  - Hot reload (apply code changes)"
echo -e "  ${GREEN}R${NC}  - Hot restart (restart app, lose state)"
echo -e "  ${GREEN}q${NC}  - Quit"
echo -e "  ${GREEN}h${NC}  - Show all commands"
echo ""
echo -e "${YELLOW}Press Ctrl+C to stop${NC}"
echo ""

# Run the app (auto-detect device)
flutter run
