//
//  audioSwitcher.cpp
//  AudioSwitcher
//
//  Created by Case Wright on 1/30/16.
//  Copyright © 2016 Case Wright. All rights reserved.
//

#include <stdio.h>
#include "audioSwitcher.h"

void setDevice(AudioDeviceID newDeviceID) {
    UInt32 propertySize = sizeof(UInt32);
    AudioHardwareSetProperty(kAudioHardwarePropertyDefaultOutputDevice, propertySize, &newDeviceID);
}

char** getDevices() {
    UInt32 propertySize;
    AudioDeviceID dev_array[64];
    int numberOfDevices = 0;
    
    AudioHardwareGetPropertyInfo(kAudioHardwarePropertyDevices, &propertySize, NULL);
    AudioHardwareGetProperty(kAudioHardwarePropertyDevices, &propertySize, dev_array);
    
    numberOfDevices = (propertySize / sizeof(AudioDeviceID));
    
    //pointer to array of pointers
    char** devices = (char**)calloc(numberOfDevices + 1, sizeof(char*));
    
    int index = 0;
    
    for(int i=0; i<sizeof(dev_array); i++) {
        if (!isAnOutputDevice(dev_array[i])) {
            continue;
        }
        
        //allocate a new string in memory for each item
        char* deviceName = calloc(1, 256);
        
        getDeviceName(dev_array[i], deviceName);
        
        devices[index] = deviceName;
        index++;
    }
    
    devices[index] = NULL;
    
    return devices;
}
void getDeviceName(AudioDeviceID deviceID, char* deviceName) {
    UInt32 propertySize = 256;
    AudioDeviceGetProperty(deviceID, 0, false, kAudioDevicePropertyDeviceName, &propertySize, deviceName);
}

char* getDeviceName2(AudioDeviceID deviceID) {
    UInt32 propertySize = 256;
    char* deviceName;
    AudioDeviceGetProperty(deviceID, 0, false, kAudioDevicePropertyDeviceName, &propertySize, deviceName);
    return deviceName;
}

bool isAnOutputDevice(AudioDeviceID deviceID) {
    UInt32 propertySize = 256;
    
    // if there are any output streams, then it is an output
    AudioDeviceGetPropertyInfo(deviceID, 0, false, kAudioDevicePropertyStreams, &propertySize, NULL);
    if (propertySize > 0) return true;
    
    return false;
}

AudioDeviceID getRequestedDeviceID(char* requestedDeviceName) {
    UInt32 propertySize;
    AudioDeviceID dev_array[64];
    int numberOfDevices = 0;
    char deviceName[256];
    
    AudioHardwareGetPropertyInfo(kAudioHardwarePropertyDevices, &propertySize, NULL);
    
    AudioHardwareGetProperty(kAudioHardwarePropertyDevices, &propertySize, dev_array);
    numberOfDevices = (propertySize / sizeof(AudioDeviceID));
    
    for(int i = 0; i < numberOfDevices; ++i) {
        if (!isAnOutputDevice(dev_array[i])) continue;
        
        getDeviceName(dev_array[i], deviceName);
        if (strcmp(requestedDeviceName, deviceName) == 0) {
            return dev_array[i];
        }
    }
    
    return kAudioDeviceUnknown;
}