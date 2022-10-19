#import <Foundation/Foundation.h>
#import "MobileWiFi.h"

typedef NS_ENUM(NSInteger, Encryption) {
    NONE = 0,
    WEP = 1,
    WPA = 2,
    EAP = 3
};

@interface IBWiFiNetwork: NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *password;
@property (nonatomic) BOOL isHidden;
@property (nonatomic) NSInteger channel;
@property (nonatomic, strong) NSDate *addedAt;
@property (nonatomic, strong) NSDate *lastAutoJoined;
@property (nonatomic, strong) NSDate *prevJoined;
@property (nonatomic, strong) NSDate *lastJoined;
@property (nonatomic) Encryption encryption;
@property (nonatomic, retain) NSDictionary *allRecords;

- (instancetype) initWithNetwork:(WiFiNetworkRef) network;
- (NSDate *) lastJoinDate;
- (NSDate *) dateForSorting;

@end