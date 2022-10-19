#import "IBWiFiManager.h"
#import "MobileWiFi.h"
#import "IBWiFiNetwork.h"

@interface IBWiFiManager ()
@property (nonatomic, retain) NSArray *unfilteredNetworks;
@property (nonatomic) WiFiManagerRef manager;
@end

@implementation IBWiFiManager

+ (instancetype) sharedManager {
	static IBWiFiManager *sharedWiFiManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedWiFiManager = [[self alloc] init];
    });
    return sharedWiFiManager;
}

- (instancetype) init {
    if(self = [super init]) {
        self.sortCriteria = [[NSUserDefaults standardUserDefaults] integerForKey:@"sortOrder"];
        [self loadNetworks];
    }
    return self;
}

- (void) refreshNetworks {
    self.networks = [self sortNetworks:self.unfilteredNetworks];
    self.unfilteredNetworks = self.networks;
}

- (void) setFilter:(NSString *)text {
    if (!text || [text isEqual:@""]) {
        self.networks = self.unfilteredNetworks;
        return;
    }

    self.networks = [self.unfilteredNetworks filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(IBWiFiNetwork *network, NSDictionary *bindings) {
        return [network.name rangeOfString:text options:NSCaseInsensitiveSearch].location != NSNotFound;
    }]];
}

- (void) loadNetworks {
    self.manager = WiFiManagerClientCreate(kCFAllocatorDefault, 0);
    if (self.manager) {
        NSArray *allNetworks = (__bridge NSArray *) WiFiManagerClientCopyNetworks(self.manager);
        NSArray *filteredNetworks = [self filterOpenNetworks:allNetworks]; 
        NSArray *mappedNetworks = [self mapNetworks:filteredNetworks];
        self.networks = [self sortNetworks:mappedNetworks];
        self.unfilteredNetworks = self.networks;
    }
}

- (NSArray *) sortNetworks: (NSArray *)networks {
    if (self.sortCriteria == NAME_ASC) {
        return [self sortByName:networks ascending:YES];
    } else if (self.sortCriteria == NAME_DESC) {
        return [self sortByName:networks ascending:NO];
    } else if (self.sortCriteria == ADDED_ASC) {
        return [self sortByAdded:networks ascending:YES];
    } else if (self.sortCriteria == ADDED_DESC) {
        return [self sortByAdded:networks ascending:NO];
    } else if (self.sortCriteria == LAST_JOINED_ASC) {
        return [self sortByLastJoined:networks ascending:YES];
    } else if (self.sortCriteria == LAST_JOINED_DESC) {
        return [self sortByLastJoined:networks ascending:NO];
    } else {
        return [self sortByLastJoined:networks ascending:NO];
    }

    return networks;
}

- (NSArray *) filterOpenNetworks:(NSArray *) networks {
    return [networks filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id network, NSDictionary *bindings) {
        return (__bridge NSString *) WiFiNetworkCopyPassword((__bridge WiFiNetworkRef)network) != NULL;
    }]];
}

- (NSArray *) mapNetworks:(NSArray *) networks {
    NSMutableArray *array = [NSMutableArray new];

    for(id network in networks) {
        [array addObject:[[IBWiFiNetwork alloc] initWithNetwork:(__bridge WiFiNetworkRef)network]];
    }

    return array;
}

- (NSArray *) sortByName:(NSArray *)networks ascending:(BOOL) ascending {
    return [networks sortedArrayUsingComparator: ^(IBWiFiNetwork *network1, IBWiFiNetwork *network2) {
        NSComparisonResult result;
		
		NSMutableString * name1 = [[NSMutableString alloc]initWithString:network1.name];
		NSMutableString * name2 = [[NSMutableString alloc]initWithString:network2.name];
		NSString *firstWord1=[network1.name substringToIndex:1];
		NSString *firstWord2=[network2.name substringToIndex:1];
		if(![network1.name length]||![network2.name length]){
			return [network1.name compare: network2.name options:NSLiteralSearch];
		}
		CFStringTransform((__bridge CFMutableStringRef)name1, NULL, kCFStringTransformToLatin, NO);
		CFStringTransform((__bridge CFMutableStringRef)name1, NULL, kCFStringTransformStripCombiningMarks, NO);
		CFStringTransform((__bridge CFMutableStringRef)name2, NULL, kCFStringTransformToLatin, NO);
		CFStringTransform((__bridge CFMutableStringRef)name2, NULL, kCFStringTransformStripCombiningMarks, NO);
		// NSLog(@"------\n%@,%@,%@,%@",name1,firstWord1,name2,firstWord2);

		NSComparisonResult result1 = [[name1 substringToIndex:1] compare:[name2 substringToIndex:1] options:NSCaseInsensitiveSearch];
		NSString *name1FirstWord=[name1 substringToIndex:1];
		NSString *name2FirstWord=[name2 substringToIndex:1];
		
		// 首字母分块
		if(result1!=NSOrderedSame){
			result= result1;
		}else {
			// 中文在后
			if([name1FirstWord isEqualToString:firstWord1]&&![name2FirstWord isEqualToString:firstWord2]){
				result= NSOrderedAscending;
			}else if(![name1FirstWord isEqualToString:firstWord1]&&[name2FirstWord isEqualToString:firstWord2]){
				result= NSOrderedDescending;
			}else{
				// 大写字母在后
				for (int i = 0; i<([name1 length]>[name2 length]?[name2 length]:[name1 length]); i++){
					char name1FirstChar=[name1 characterAtIndex:i];
					char name2FirstChar=[name2 characterAtIndex:i];
					if((name1FirstChar>='a'&&name1FirstChar<='z')&&(name2FirstChar>='A'&&name2FirstChar<='Z')){
						result= NSOrderedAscending;
					}else if((name1FirstChar>='A'&&name1FirstChar<='Z')&&(name2FirstChar>='a'&&name2FirstChar<='z')){
						result= NSOrderedDescending;
					}
				}
				if(result){
					if([name1 length]>[name2 length]){
						result= NSOrderedDescending;
					}else if([name1 length]<[name2 length]){
						result= NSOrderedAscending;
					}else{
						result= NSOrderedSame;
					}
				}
			}
		}
		
		
		
		
        if (ascending) {
            return result;
        } else if (result == NSOrderedAscending) {
            result = NSOrderedDescending;
        } else if (result == NSOrderedDescending) {
            result = NSOrderedAscending;
        }
        return result;
    }];
}

- (NSArray *) sortByAdded:(NSArray *)networks ascending:(BOOL) ascending {
    return [networks sortedArrayUsingComparator: ^(IBWiFiNetwork *network1, IBWiFiNetwork *network2) {
        NSComparisonResult result = [[network1 dateForSorting] compare:[network2 dateForSorting]];
        if (ascending) {
            return result;
        } else if (result == NSOrderedAscending) {
            result = NSOrderedDescending;
        } else if (result == NSOrderedDescending) {
            result = NSOrderedAscending;
        }
        return result;
    }];
}

- (NSArray *) sortByLastJoined:(NSArray *)networks ascending:(BOOL) ascending {
    return [networks sortedArrayUsingComparator: ^(IBWiFiNetwork *network1, IBWiFiNetwork *network2) {
        NSComparisonResult result = [[network1 lastJoinDate] compare:[network2 lastJoinDate]];
        if (ascending) {
            return result;
        } else if (result == NSOrderedAscending) {
            result = NSOrderedDescending;
        } else if (result == NSOrderedDescending) {
            result = NSOrderedAscending;
        }
        return result;
    }];
}

- (void) forgetNetwork:(IBWiFiNetwork *)network {
    NSArray *allNetworks = (__bridge NSArray *) WiFiManagerClientCopyNetworks(self.manager);
    NSArray *filteredNetworks = [self filterOpenNetworks:allNetworks]; 
    
    for(id networkRef in filteredNetworks) {
        NSString *ssid = (__bridge NSString *) WiFiNetworkGetSSID((__bridge WiFiNetworkRef) networkRef);

        if([ssid isEqualToString:network.name]) {
            WiFiManagerClientRemoveNetwork(self.manager, (__bridge WiFiNetworkRef) networkRef);
            [self loadNetworks];
            break;
        }
    }
}

@end