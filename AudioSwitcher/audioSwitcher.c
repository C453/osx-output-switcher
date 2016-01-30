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
