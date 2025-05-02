#!/bin/bash
echo "모든 Xcode 관련 프로세스 종료 중..."
killall Xcode
killall -9 com.apple.dt.Xcode.AttachToXPCService
killall -9 com.apple.dt.Xcode.SimulatorTrampoline
killall -9 ibtoold
killall -9 xcdevice
killall -9 xcrun
