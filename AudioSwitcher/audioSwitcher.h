//
//  audioSwitcher.h
//  AudioSwitcher
//
//  Created by Case Wright on 1/30/16.
//  Copyright © 2016 Case Wright. All rights reserved.
//

#include <CoreAudio/CoreAudio.h>

void setDevice(AudioDeviceID newDeviceID);
void getDeviceName(AudioDeviceID deviceID, char* deviceName);
bool isAnOutputDevice(AudioDeviceID deviceID);
AudioDeviceID getRequestedDeviceID(char* requestedDeviceName);
char** getDevices();
char* getDeviceName2(AudioDeviceID deviceID);