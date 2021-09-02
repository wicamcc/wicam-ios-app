//
//  helper.h
//  Open Wicam
//
//  Created by Yunfeng Liu on 2016-07-12.
//  Copyright © 2016 Armstart. All rights reserved.
//

#ifndef helper_h
#define helper_h

#include <stdio.h>
#include <MiniUPnPc/miniupnpc.h>
#include <MiniUPnPc/upnpcommands.h>
#include <MiniUPnPc/upnpdev.h>

#define SSID_LEN_MAX   32
#define MAX_PIN_LEN     12
#pragma pack(push,1)
typedef struct _main_conf{
    uint8_t version; //fw version, initial ver = 1.
    uint8_t  switch_mode; // sitch to xxx mode on restart, 0=none, 1=ap, 2=sta_static_ip
    uint16_t  rsvd2; // 保留，以后版本使用。
    char ap_ssid[SSID_LEN_MAX+1]; //default WiCam-XXXXXXXX, XXXXXX为CC3200Mac地址的第2,3,4,5个字节。
    char ap_pin[MAX_PIN_LEN+1]; //default wicam.cc
    char sta_ssid[SSID_LEN_MAX + 1];  //没有被配置的话sta_bssid[0:8]= 0; 代表记录不存在。
    char sta_pin[MAX_PIN_LEN+1]; //没有被配置的话sta_pin[X] [0]= 0;
    uint8_t sta_sec; //如：SL_SEC_TYPE_WPA_WPA2
    uint32_t static_ip; // 4 bytes
    uint8_t		rsvd3[28];
}main_conf_t;
#pragma(pop)

#endif /* helper_h */
