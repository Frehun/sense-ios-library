//
//  AntDevicesWahooDongle.h
//  sensePlatform
//
//  Created by Pim Nijdam on 3/30/12.
//  Copyright (c) 2012 Almende B.V. All rights reserved.
//
#if 0

#import <UIKit/UIKit.h>
#import <WFConnector/WFConnector.h>
#import <WFConnector/WFAntFs.h>

@interface CSAntPlusController : NSObject <WFHardwareConnectorDelegate, WFAntFSDeviceDelegate> {
    UITextView* textView;
}


//DEBUG API
- (id) initWithTextView:(UITextView*) tv;
- (void) connectToBloodPressure;
- (void) scan;
- (void) getDirectoryInfo;
- (void) syncTime;
@end

#endif