#import <UIKit/UIKit.h>

#pragma mark - API settings

extern NSString *const CaronaeAPIBaseURL;


#pragma mark - Static pages URLs

extern NSString *const CaronaeIntranetURLString;
extern NSString *const CaronaeAboutPageURLString;
extern NSString *const CaronaeTermsOfUsePageURLString;


#pragma mark - Preference keys

extern NSString *const CaronaePreferenceLastSearchedNeighborhoodsKey;
extern NSString *const CaronaePreferenceLastSearchedCenterKey;
extern NSString *const CaronaePreferenceLastSearchedDateKey;
extern NSString *const CaronaePreferenceLastSearchedDirectionKey;


#pragma mark - Notifications

extern NSString *const CaronaeNotificationReceivedNotification;
extern NSString *const CaronaeDidUpdateNotifications;


#pragma mark - Error types

extern NSString *const CaronaeErrorDomain;
extern const NSInteger CaronaeErrorInvalidResponse;
extern const NSInteger CaronaeErrorNoRidesCreated;
extern const NSInteger CaronaeErrorOpeningCoreDataStore;


#pragma mark - Etc.

extern NSString *const Caronae8PhoneNumberPattern;
extern NSString *const Caronae9PhoneNumberPattern;
extern NSString *const CaronaePlaceholderProfileImage;
extern NSString *const CaronaeSearchDateFormat;
extern NSString *const CaronaeDateLocaleIdentifier;


@interface CaronaeConstants : NSObject

+ (instancetype)defaults;

+ (UIColor *)colorForZone:(NSString *)zone;

@property (nonatomic, readonly) NSArray *centers;
@property (nonatomic, readonly) NSArray *hubs;
@property (nonatomic, readonly) NSArray *zones;
@property (nonatomic, readonly) NSDictionary *zoneColors;
@property (nonatomic, readonly) NSDictionary *neighborhoods;

@end
