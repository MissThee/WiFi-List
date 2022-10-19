#import "IBWiFiNetwork.h"

@implementation IBWiFiNetwork

- (instancetype) initWithNetwork:(WiFiNetworkRef) network {
    if(self = [super init]) {
        self.name = (__bridge NSString *) WiFiNetworkGetSSID(network);
        self.password = (__bridge NSString *) WiFiNetworkCopyPassword(network);
        self.allRecords = (__bridge NSDictionary *) WiFiNetworkCopyRecord(network);
		self.isHidden = [[self.allRecords objectForKey:@"HIDDEN_NETWORK"] boolValue];
		self.channel = [[self.allRecords objectForKey:@"CHANNEL"] integerValue];
		
        self.addedAt = [self.allRecords objectForKey:@"addedAt"];
        self.lastAutoJoined = [self.allRecords objectForKey:@"lastAutoJoined"];
		self.prevJoined = [self.allRecords objectForKey:@"prevJoined"];
		self.lastJoined = [self.allRecords objectForKey:@"lastJoined"];
        if (WiFiNetworkIsWEP(network)) {
            self.encryption = WEP;
        } else if (WiFiNetworkIsWPA(network)) {
            self.encryption = WPA;
        } else if (WiFiNetworkIsEAP(network)) {
            self.encryption = EAP;
        } else {
            self.encryption = NONE;
        }
    }
    return self;
}

- (NSDate *) lastJoinDate {
	NSMutableArray* dates = [[NSMutableArray alloc] init];
	[dates addObject:[NSDate dateWithTimeIntervalSince1970:0]];
	if(self.addedAt){
		 [dates addObject:self.addedAt];
	}
	if(self.lastAutoJoined){
		 [dates addObject:self.lastAutoJoined];
	}
	if(self.prevJoined){
		 [dates addObject:self.prevJoined];
	}
	if(self.lastJoined){
		 [dates addObject:self.lastJoined];
	}
	return [[dates sortedArrayUsingComparator:^NSComparisonResult(NSDate *date1, NSDate *date2){
		return [date2 compare: date1];
    }] objectAtIndex:0]; 
	
    //if (!self.lastManualJoin && !self.lastAutoJoin) {
    //    return [NSDate dateWithTimeIntervalSince1970:0];
    //} else if ([self.lastManualJoin compare:self.lastAutoJoin] == NSOrderedDescending) {
    //    return self.lastManualJoin;
    //}
    //return self.lastAutoJoin;
}

- (NSDate *) dateForSorting {
    if (!self.addedAt) {
        return [NSDate dateWithTimeIntervalSince1970:0];
    }

    return self.addedAt;
}

@end