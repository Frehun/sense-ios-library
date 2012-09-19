//
//  Settings.m
//  senseLocationApp
//
//  Created by Pim Nijdam on 2/18/11.
//  Copyright 2011 Almende. All rights reserved.
//

#import "CSSettings.h"

//notifications
NSString* const CSsettingLoginChangedNotification = @"CSsettingLoginChangedNotification";
NSString* const CSanySettingChangedNotification = @"CSanySettingChangedNotification";

//setting types
NSString* const kCSSettingTypeGeneral = @"general";
NSString* const kCSSettingTypeBiometric = @"biometric";
NSString* const kCSSettingTypeActivity = @"activity";
NSString* const kCSSettingTypeLocation = @"position";
NSString* const kCSSettingTypeSpatial = @"spatial";
NSString* const kCSSettingTypeAmbience = @"ambience";

//general settings keys
NSString* const kCSGeneralSettingSenseEnabled = @"senseEnabled";
NSString* const kCSGeneralSettingUsername = @"username";
NSString* const kCSGeneralSettingPassword = @"password";
NSString* const kCSGeneralSettingUploadInterval = @"synchronisationRate";
NSString* const kCSGeneralSettingPollInterval = @"pollRate";
NSString* const kCSGeneralSettingAutodetect = @"auto detect";
NSString* const kCSGeneralSettingUploadToCommonSense = @"upload to CommonSense";

//biometric settings
NSString* const kCSBiometricSettingGender = @"gender";
NSString* const kCSBiometricSettingBirthDate = @"birth date";
NSString* const kCSBiometricSettingWeight = @"weight";
NSString* const kCSBiometricSettingHeight = @"height";
NSString* const kCSBiometricSettingBodyFat = @"body fat";
NSString* const kCSBiometricSettingMaxPulse = @"max pulse";

//activity settings
NSString* const kCSActivitySettingDetection = @"detection";
NSString* const kCSActivitySettingPrivacy = @"privacy";

//location settings keys
NSString* const kCSLocationSettingAccuracy = @"accuracy";
NSString* const kCSLocationSettingMinimumDistance = @"minimumDistance";

//spatial settings
NSString* const kCSSpatialSettingInterval = @"pollInterval";
NSString* const kCSSpatialSettingFrequency = @"frequency";
NSString* const kCSSpatialSettingNrSamples = @"number of samples";

//ambiance settings
NSString* const kCSAmbienceSettingInterval = @"pollInterval";

//categorical values
NSString* const kCSSettingYES = @"1";
NSString* const kCSSettingNO = @"0";

NSString* const kCSGeneralSettingUploadIntervalNightly = @"nightly";
NSString* const kCSGeneralSettingUploadIntervalWifi = @"wifi";
NSString* const kCSGeneralSettingUploadIntervalAdaptive = @"adaptive";

//biometric
NSString* const kCSBiometricSettingGenderMale = @"male";
NSString* const kCSBiometricSettingGenderFemale = @"female";

//activity detection
NSString* const kCSActivitySettingDetectionDetectOnly = @"detect only";
NSString* const kCSActivitySettingDetectionIgnore = @"ignore";
NSString* const kCSActivitySettingDetectionDetectAndUpload = @"detect and upload";

//activity privacy
NSString* const kCSActivitySettingPrivacyPrivate = @"private";
NSString* const kCSActivitySettingPrivacyFriends = @"friends";
NSString* const kCSActivitySettingPrivacyFriendsOfFriends = @"friends of friends";
NSString* const kCSActivitySettingPrivacyActivitiesCommunity = @"activities community";
NSString* const kCSActivitySettingPrivacyPublic = @"public";

@implementation CSSetting
@synthesize name;
@synthesize value;
@end


@interface CSSettings (private) 
- (void) storeSettings;
- (void) loadSettingsFromPath:(NSString*)path;
- (void) anySettingChanged:(NSString*)setting value:(NSString*)value;
@end

@implementation CSSettings {
@private NSMutableDictionary* settings;
@private NSMutableDictionary* general;
@private NSMutableDictionary* location;
@private NSMutableDictionary* sensorEnables;
}
//@synthesize general;
//@synthesize location;

//Singleton instance
static CSSettings* sharedSettingsInstance = nil;

+ (CSSettings*) sharedSettings {
	if (sharedSettingsInstance == nil) {
		sharedSettingsInstance = [[super allocWithZone:NULL] init];
	}
	return sharedSettingsInstance;	
}

//override to ensure singleton
+ (id)allocWithZone:(NSZone *)zone
{
    return [self sharedSettings];
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}


- (id) init {
	self = [super init];
	if (self) {
		//initialise settings from plist
        NSString* plistPath;
		
		//Try to load saved settings
        NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
																  NSUserDomainMask, YES) objectAtIndex:0];
        plistPath = [rootPath stringByAppendingPathComponent:@"Settings.plist"];
        if (![[NSFileManager defaultManager] fileExistsAtPath:plistPath]) {
			//fallback to default settings
			plistPath = [[NSBundle mainBundle] pathForResource:@"CSSettings" ofType:@"plist"];
        }
		@try {
			[self loadSettingsFromPath:plistPath];
		}
		@catch (NSException * e) {
			NSLog(@"Settings: exception thrown while loading settings: %@", e);
			settings = nil;
		}
		if (settings == nil) {
			//fall back to defaults
			@try {
				[self loadSettingsFromPath:[[NSBundle mainBundle] pathForResource:@"CSSettings" ofType:@"plist"]];
			}
			@catch (NSException * e) {
				NSLog(@"Settings: exception thrown while loading default settings. THIS IS VERY SERIOUS: %@", e);
				settings = nil;
			}
		}
        [self ensureLatestVersion];
	}
	return self;
}

#pragma mark - 
#pragma mark Settings

+ (NSString*) enabledChangedNotificationNameForSensor:(NSString*) sensor {
	return [NSString stringWithFormat:@"%@CSEnabledChangedNotification", sensor];
}

+ (NSString*) settingChangedNotificationNameForSensor:(NSString*) sensor {
	return [NSString stringWithFormat:@"%@CSSettingChangedNotification", sensor];
}

+ (NSString*) settingChangedNotificationNameForType:(NSString*) type {
	return [NSString stringWithFormat:@"%@CSSettingChangedNotificationType", type];
}

- (BOOL) isSensorEnabled:(NSString*) sensor {
	NSString* key = [NSString stringWithFormat:@"%@", sensor];
	id object = [sensorEnables objectForKey:key];
	BOOL enabled = object == nil? NO : [object boolValue];
	return enabled;
}

- (void) sendNotificationForSensor:(NSString*) sensor {
	NSString* key = [NSString stringWithFormat:@"%@", sensor];
	id object = [sensorEnables objectForKey:key];
	BOOL enabled = object == nil? NO : [object boolValue];
	NSNumber* enableObject = [NSNumber numberWithBool:enabled];
	
	[[NSNotificationCenter defaultCenter] postNotification: [NSNotification notificationWithName:[[self class] enabledChangedNotificationNameForSensor:sensor] object:enableObject]];
}

- (BOOL) setSensor:(NSString*) sensor enabled:(BOOL) enable {
    return [self setSensor:sensor enabled:enable permanent:YES];
}

- (BOOL) setSensor:(NSString*) sensor enabled:(BOOL) enable permanent:(BOOL) permanent {
	NSNumber* enableObject = [NSNumber numberWithBool:enable];
    NSString* key = [NSString stringWithFormat:@"%@", sensor];
    if (permanent) {
        //store enable settings
        [sensorEnables setObject:enableObject forKey:key];
        //write back to file
        [self storeSettings];
    }
	//notify registered subscribers
	[[NSNotificationCenter defaultCenter] postNotification: [NSNotification notificationWithName:[[self class] enabledChangedNotificationNameForSensor:sensor] object:enableObject]];
	[self anySettingChanged:key value:enable?@"true":@"false"];
	return YES;
}

- (BOOL) setLogin:(NSString*)user withPassword:(NSString*) password {
    NSLog(@"Settings setLogin:%@", user);
    [self setSettingType:kCSSettingTypeGeneral setting:kCSGeneralSettingUsername value:user];
    [self setSettingType:kCSSettingTypeGeneral setting:kCSGeneralSettingPassword value:password];
	//notify registered subscribers
	[[NSNotificationCenter defaultCenter] postNotification: [NSNotification notificationWithName:CSsettingLoginChangedNotification object:nil]];
	return YES;
}


- (NSString*) getSettingType: (NSString*) type setting:(NSString*) setting {
	NSString* name = [NSString stringWithFormat:@"SettingsType%@", type];
	NSMutableDictionary* typeSettings = [settings valueForKey:name];
	if (typeSettings != nil) {
		return [typeSettings objectForKey: setting];
	}
	return nil;
}

- (BOOL) setSettingType: (NSString*) type setting:(NSString*) setting value:(NSString*) value {
    return [self setSettingType:type setting:setting value:value persistent: YES];
}

- (BOOL) setSettingType: (NSString*) type setting:(NSString*) setting value:(NSString*) value persistent:(BOOL)persistent {
    if (persistent) {
        //get sensor settings;
        NSString* name = [NSString stringWithFormat:@"SettingsType%@", type];
        NSMutableDictionary* typeSettings = [settings valueForKey:name];
        if (typeSettings == nil) {
            //create if it doesn't already exist
            typeSettings = [NSMutableDictionary new];
            [settings setObject:typeSettings forKey:name];
        }
        
        //commit setting
        [typeSettings setObject:value forKey:setting];
        [self storeSettings];
    }
	
	//create notification object
	CSSetting* notificationObject = [[CSSetting alloc] init];
	notificationObject.name = setting;
	notificationObject.value = value;
	
	//send notification
	[[NSNotificationCenter defaultCenter] postNotification: [NSNotification notificationWithName:[[self class] settingChangedNotificationNameForType:type] object:notificationObject]];
	[self anySettingChanged:setting value:value];
	
	//free
	
	return YES;
}



#pragma mark -
#pragma mark Private

- (void) anySettingChanged:(NSString*)setting value:(NSString*)value {
	//create notification object
	CSSetting* notificationObject = [[CSSetting alloc] init];
	notificationObject.name = setting;
	notificationObject.value = value;
	
	//send notification
	[[NSNotificationCenter defaultCenter] postNotification: [NSNotification notificationWithName:CSanySettingChangedNotification object:notificationObject]];
	
}

- (void) loadSettingsFromPath:(NSString*)path {
	NSLog(@"Loading settings from %@", path);
	NSString* errorDesc = nil;
	NSPropertyListFormat format;
	
	NSData* plistXML = [[NSFileManager defaultManager] contentsAtPath:path];
	settings = (NSMutableDictionary *)[NSPropertyListSerialization
									   propertyListFromData:plistXML
									   mutabilityOption:NSPropertyListMutableContainersAndLeaves
									   format:&format
									   errorDescription:&errorDesc];
	if (!settings)
	{
		NSLog(@"Error reading plist: %@, format: %d", errorDesc, format);
		return;
	}
	//instantiate subsections of settings
	general = [settings valueForKey:@"general"];
	location = [settings valueForKey:@"location"];
	sensorEnables = [settings valueForKey:@"sensorEnables"];
	if (sensorEnables == nil) {
		sensorEnables = [NSMutableDictionary new];
		[settings setObject:sensorEnables forKey:@"sensorEnables"];
	}
}

- (void) storeSettings {
	@try {
		NSString *error;
		NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
		NSString *plistPath = [rootPath stringByAppendingPathComponent:@"Settings.plist"];
		NSData *plistData = [NSPropertyListSerialization dataFromPropertyList:settings
																	   format:NSPropertyListXMLFormat_v1_0
															 errorDescription:&error];
		if(plistData) {
			[plistData writeToFile:plistPath atomically:YES];
		}
		else {
			NSLog(@"%@", error);
		}
	}
	@catch (NSException * e) {
		NSLog(@"Settings:Exception thrown while storing settings: %@", e);
	}
}

- (void) ensureLatestVersion {
    //open default settings
    NSString* errorDesc = nil;
	NSPropertyListFormat format;
    NSString* defaultPath = [[NSBundle mainBundle] pathForResource:@"CSSettings" ofType:@"plist"];
    NSData* plistXML = [[NSFileManager defaultManager] contentsAtPath:defaultPath];
	NSDictionary* defaultSettings = (NSDictionary *)[NSPropertyListSerialization
                                                     propertyListFromData:plistXML
                                                     mutabilityOption:NSPropertyListMutableContainersAndLeaves
                                                     format:&format
                                                     errorDescription:&errorDesc];
	if (!defaultSettings)
	{
		NSLog(@"Error reading plist: %@, format: %d", errorDesc, format);
		return;
	}
    
    //copy settings that aren't in the local settings with the default settings
    
    for (NSString* key in defaultSettings) {
        if ([settings valueForKey:key] == nil) {
            [settings setValue:[defaultSettings objectForKey:key] forKey:key];
        }
    }
    
}
@end