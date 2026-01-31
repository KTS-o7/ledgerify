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

# Get list of available emulators
echo -e "${YELLOW}Checking available emulators...${NC}"
EMULATORS=$(flutter emulators 2>/dev/null | grep -E "^[A-Za-z]" | grep -v "available" | grep -v "To run" | grep -v "To create" | grep -v "You can" | awk '{print $1}')

if [ -z "$EMULATORS" ]; then
    echo -e "${RED}No emulators found. Please create one using Android Studio.${NC}"
    echo -e "${YELLOW}Run: flutter emulators --create --name dev_phone${NC}"
    exit 1
fi

# Get the first emulator
EMULATOR_ID=$(echo "$EMULATORS" | head -n 1)
echo -e "${GREEN}Found emulator: ${EMULATOR_ID}${NC}"

# Check if emulator is already running
echo -e "${YELLOW}Checking for running devices...${NC}"
RUNNING_DEVICES=$(flutter devices 2>/dev/null | grep -i "emulator\|android" | grep -v "No devices" || true)

if [ -n "$RUNNING_DEVICES" ]; then
    echo -e "${GREEN}Emulator already running!${NC}"
    echo "$RUNNING_DEVICES"
else
    # Launch emulator
    echo -e "${YELLOW}Launching emulator: ${EMULATOR_ID}${NC}"
    flutter emulators --launch "$EMULATOR_ID" &
    
    # Wait for emulator to boot
    echo -e "${YELLOW}Waiting for emulator to boot (this may take 30-60 seconds)...${NC}"
    
    COUNTER=0
    MAX_WAIT=90
    while [ $COUNTER -lt $MAX_WAIT ]; do
        DEVICE_READY=$(flutter devices 2>/dev/null | grep -i "emulator" || true)
        if [ -n "$DEVICE_READY" ]; then
            echo -e "${GREEN}Emulator is ready!${NC}"
            break
        fi
        sleep 2
        COUNTER=$((COUNTER + 2))
        echo -ne "\r${YELLOW}Waiting... ${COUNTER}s${NC}  "
    done
    
    if [ $COUNTER -ge $MAX_WAIT ]; then
        echo -e "${RED}Timeout waiting for emulator to boot${NC}"
        exit 1
    fi
    echo ""
fi

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

# Run the app
flutter run
