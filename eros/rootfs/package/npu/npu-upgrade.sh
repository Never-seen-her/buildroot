#!/bin/sh
# RK3399Pro NPU firmware upgrade, based on the A MATRIZ npu_upgrade flow.
# Usage: npu-upgrade.sh [--yes] [loader.bin uboot.img trust.img boot.img]

PROGRAM=${0##*/}
SCRIPT_DIR=$(CDPATH= cd "$(dirname "$0")" 2>/dev/null && pwd) || {
    echo "$PROGRAM: cannot determine script directory" >&2
    exit 1
}
TOOL=${NPU_UPGRADE_TOOL:-}
LOG=${NPU_UPGRADE_LOG:-/tmp/npu-upgrade.log}
AUTO_CONFIRM=0

usage() {
    echo "Usage: $PROGRAM [--yes] [MiniLoaderAll.bin uboot.img trust.img boot.img]" >&2
    echo "Without firmware arguments, files are read from /usr/lib/firmware/npu/." >&2
    echo "Set NPU_UPGRADE_TOOL if an architecture-compatible upgrade_tool is not in PATH or beside this script." >&2
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --yes)
            AUTO_CONFIRM=1
            shift
            ;;
        --)
            shift
            break
            ;;
        -* )
            usage
            exit 2
            ;;
        *)
            break
            ;;
    esac
done

case "$#" in
    0)
        FIRMWARE_DIR=/usr/lib/firmware/npu
        LOADER=$FIRMWARE_DIR/MiniLoaderAll.bin
        UBOOT=$FIRMWARE_DIR/uboot.img
        TRUST=$FIRMWARE_DIR/trust.img
        BOOT=$FIRMWARE_DIR/boot.img
        ;;
    4)
        LOADER=$1
        UBOOT=$2
        TRUST=$3
        BOOT=$4
        ;;
    *)
        usage
        exit 2
        ;;
esac

if [ "$(id -u)" -ne 0 ]; then
    echo "$PROGRAM: run as root (for example, with sudo)" >&2
    exit 1
fi

if [ -z "$TOOL" ]; then
    if [ -x "$SCRIPT_DIR/upgrade_tool" ]; then
        TOOL=$SCRIPT_DIR/upgrade_tool
    else
        TOOL=$(command -v upgrade_tool 2>/dev/null) || TOOL=
    fi
fi
if [ -z "$TOOL" ] || ! command -v "$TOOL" >/dev/null 2>&1; then
    echo "$PROGRAM: upgrade_tool not found; set NPU_UPGRADE_TOOL" >&2
    exit 1
fi

for image in "$LOADER" "$UBOOT" "$TRUST" "$BOOT"; do
    if [ ! -f "$image" ] || [ ! -r "$image" ]; then
        echo "$PROGRAM: firmware file missing or unreadable: $image" >&2
        exit 1
    fi
done

: >> "$LOG" || {
    echo "$PROGRAM: cannot write log: $LOG" >&2
    exit 1
}
printf '\n[%s] NPU firmware upgrade started\n' "$(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null || date)" >> "$LOG"

run_tool() {
    "$TOOL" "$@" >> "$LOG" 2>&1
}

# The article uses `upgrade_tool ld` as a readiness check before downloading.
ready=0
attempt=1
while [ "$attempt" -le 10 ]; do
    echo "Checking NPU USB/Maskrom device ($attempt/10)..."
    if run_tool ld; then
        ready=1
        break
    fi
    attempt=$((attempt + 1))
    [ "$attempt" -le 10 ] && sleep 1
done

if [ "$ready" -ne 1 ]; then
    echo "$PROGRAM: NPU not detected by upgrade_tool after 10 attempts." >&2
    echo "Power the NPU with npu-power, check its USB connection, then retry." >&2
    echo "Recent tool output ($LOG):" >&2
    tail -n 40 "$LOG" >&2
    exit 1
fi

echo "WARNING: this writes firmware to the NPU. Use matching RK3399Pro NPU images."
if [ "$AUTO_CONFIRM" -ne 1 ]; then
    printf 'Continue with NPU firmware upgrade? Type YES to continue: '
    IFS= read -r answer || answer=
    case "$answer" in
        YES|yes|Yes) ;;
        *) echo "Cancelled."; exit 1 ;;
    esac
fi

run_step() {
    description=$1
    shift
    echo "$description..."
    if run_tool "$@"; then
        echo "  done"
        return 0
    else
        result=$?
        echo "$PROGRAM: $description failed (upgrade_tool exit $result)." >&2
        echo "Tool output ($LOG):" >&2
        tail -n 40 "$LOG" >&2
        return "$result"
    fi
}

# Addresses and command order follow the article's NPU-specific upgrade script.
run_step "Downloading loader" db "$LOADER" || exit 1
sleep 1
run_step "Waiting for loader" td || exit 1
run_step "Writing uboot at 0x40000" wl 0x40000 "$UBOOT" || exit 1
run_step "Writing trust at 0x40800" wl 0x40800 "$TRUST" || exit 1
run_step "Writing boot at 0x20000" wl 0x20000 "$BOOT" || exit 1
run_step "Starting NPU firmware" rs 0x40000 0x40800 0x20000 "$UBOOT" "$TRUST" "$BOOT" || exit 1

printf '[%s] NPU firmware upgrade completed\n' "$(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null || date)" >> "$LOG"
echo "NPU firmware upgrade commands completed. Log: $LOG"
echo "Check dmesg and USB enumeration, then verify with npu_transfer_proxy devices."
