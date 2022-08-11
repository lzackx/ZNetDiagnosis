//
//  ZViewController.m
//  ZNetDiagnosis
//
//  Created by lZackx on 08/03/2022.
//  Copyright (c) 2022 lZackx. 
//

#import "ZViewController.h"

#import <ZNetDiagnosis/ZNetDiagnosis+ping.h>
#import <ZNetDiagnosis/ZNetDiagnosis+traceroute.h>


@interface ZViewController ()

@end

@implementation ZViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	
    [self traceroute];
    
//    [self ping];
}

- (void)traceroute {
    
    
    ZNDTracerouteConfiguration *configration = [[ZNDTracerouteConfiguration alloc] init];
    configration.target = @"m.qeeq.com";
    configration.tracerouteProtocol = ZNDTracerouteProtocolICMP;
    configration.attempt = 3;
    configration.maxTTL = 64;
    
    [[ZNetDiagnosis shared] tracerouteWithConfiguration:configration success:^(NSDictionary * _Nonnull info) {
//        NSLog(@"%@", info);
    } failure:^(NSDictionary * _Nonnull info) {
//        NSLog(@"%@", info);
    } completion:^(NSDictionary * _Nonnull info) {
//        NSLog(@"%@", info);
    }];
    
    [[ZNetDiagnosis shared] tracerouteWithConfiguration:configration];
}

- (void)ping {
    ZNDPingConfiguration *pingConfigration = [[ZNDPingConfiguration alloc] init];
    pingConfigration.target = @"m.google.com";
    pingConfigration.pingProtocol = ZNDPingProtocolICMP;
    pingConfigration.attempt = 3;
    pingConfigration.maxTTL = 64;
    pingConfigration.timeout = 1;
    
    [[ZNetDiagnosis shared] pingWithConfiguration:pingConfigration success:^(NSDictionary * _Nonnull info) {
        NSLog(@"%@", info);
    } failure:^(NSDictionary * _Nonnull info) {
        NSLog(@"%@", info);
    } completion:^(NSDictionary * _Nonnull info) {
        NSLog(@"%@", info);
    }];
    
    [[ZNetDiagnosis shared] pingWithConfiguration:pingConfigration];
}

@end
