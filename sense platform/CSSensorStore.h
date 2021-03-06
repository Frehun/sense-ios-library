/* Copyright (©) 2012 Sense Observation Systems B.V.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * Author: Pim Nijdam (pim@sense-os.nl)
 */

#import <Foundation/Foundation.h>
#import "CSDataStore.h"
#import "CSSender.h"
#import "CSSensor.h"

@interface CSSensorStore : NSObject <CSDataStore> {
}

@property (readonly) NSArray* allAvailableSensorClasses;
@property (readonly) NSArray* sensors;
@property (readonly) CSSender* sender;


+ (CSSensorStore*) sharedSensorStore;
+ (NSDictionary*) device;

- (id)init;
- (void) loginChanged;
- (void) setEnabled:(BOOL) enable;
- (void) enabledChanged:(id) notification;
- (void) setSyncRate: (int) newRate;
- (void) addSensor:(CSSensor*) sensor;
- (NSArray*) getDataForSensor:(NSString*) name onlyFromDevice:(bool) onlyFromDevice nrLastPoints:(NSInteger) nrLastPoints;
- (void) giveFeedbackOnState:(NSString*) state from:(NSDate*)from to:(NSDate*) to label:(NSString*)label;

/* Ensure all sensor data is flushed, used to reduce memory usage.
 * Flushing in this order, on failure continue with the next:
 * - flush to server
 * - flush to disk (not impemented)
 * - delete
 */
- (void) forceDataFlush;
- (void) forceDataFlushAndBlock;
- (void) generalSettingChanged: (NSNotification*) notification;


@end
