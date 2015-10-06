/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <XCTest/XCTest.h>

#import <FBSimulatorControl/FBSimulator.h>
#import <FBSimulatorControl/FBSimulatorApplication.h>
#import <FBSimulatorControl/FBSimulatorControlConfiguration.h>
#import <FBSimulatorControl/FBSimulatorPool+Private.h>
#import <FBSimulatorControl/FBSimulatorPool.h>

#import "CoreSimulatorDoubles.h"

@interface FBSimulatorPoolTests : XCTestCase

@property (nonatomic, strong) FBSimulatorPool *pool;

@end

@implementation FBSimulatorPoolTests

- (void)teardown
{
  self.pool = nil;
}

+ (NSDictionary *)keySimulatorsByName:(id<NSFastEnumeration>)simulators
{
  NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
  for (FBSimulator *simulator in simulators) {
    dictionary[simulator.name] = simulator;
  }
  return dictionary;
}

- (NSArray *)createPoolWithExistingSimDeviceSpecs:(NSArray *)simulatorspecs
{
  NSMutableArray *simulators = [NSMutableArray array];
  for (NSDictionary *simulatorspec in simulatorspecs) {
    NSString *name = simulatorspec[@"name"];
    NSUUID *uuid = simulatorspec[@"uuid"] ?: [NSUUID UUID];
    FBSimulatorState state = [(simulatorspec[@"state"] ?: @(FBSimulatorStateShutdown)) integerValue];

    FBSimulatorControlTests_SimDevice_Double *device = [FBSimulatorControlTests_SimDevice_Double new];
    device.name = name;
    device.UDID = uuid;
    device.state = state;

    [simulators addObject:device];
  }

  FBSimulatorControlTests_SimDeviceSet_Double *deviceSet = [FBSimulatorControlTests_SimDeviceSet_Double new];
  deviceSet.availableDevices = [simulators copy];

  FBSimulatorControlConfiguration *poolConfig = [FBSimulatorControlConfiguration
    configurationWithSimulatorApplication:[FBSimulatorApplication simulatorApplicationWithError:nil]
    deviceSetPath:nil
    options:0];
  self.pool = [FBSimulatorPool poolWithConfiguration:poolConfig deviceSet:(id)deviceSet];

  return deviceSet.availableDevices;
}

- (void)mockAllocationOfSimulatorsUDIDs:(NSArray *)deviceUDIDs
{
  for (NSUUID *udid in deviceUDIDs) {
    [self.pool.allocatedUDIDs addObject:udid.UUIDString];
  }
}

- (void)testInflatesSimulators
{
  [self createPoolWithExistingSimDeviceSpecs:@[
    @{@"name" : @"iPad 2", @"state" : @(FBSimulatorStateBooted)},
    @{@"name" : @"iPhone 5", @"state" : @(FBSimulatorStateCreating)},
    @{@"name" : @"iPhone 5", @"state" : @(FBSimulatorStateShutdown)},
    @{@"name" : @"iPad 3", @"state" : @(FBSimulatorStateCreating)},
    @{@"name" : @"iPhone 6S", @"state" : @(FBSimulatorStateShuttingDown) },
    @{@"name" : @"iPhone 5", @"state" : @(FBSimulatorStateBooted)},
    @{@"name" : @"iPhone 5", @"state" : @(FBSimulatorStateShutdown)},
    @{@"name" : @"iPad", @"state" : @(FBSimulatorStateBooted)}
  ]];

  NSOrderedSet *simulators = self.pool.allSimulators;
  XCTAssertEqual(simulators.count, 8);

  XCTAssertEqualObjects([simulators[0] name], @"iPad 2");
  XCTAssertEqual([simulators[0] state], FBSimulatorStateBooted);
  XCTAssertEqual([simulators[0] pool], self.pool);

  XCTAssertEqualObjects([simulators[1] name], @"iPhone 5");
  XCTAssertEqual([simulators[1] state], FBSimulatorStateCreating);
  XCTAssertEqual([simulators[1] pool], self.pool);

  XCTAssertEqualObjects([simulators[2] name], @"iPhone 5");
  XCTAssertEqual([simulators[2] state], FBSimulatorStateShutdown);
  XCTAssertEqual([simulators[2] pool], self.pool);

  XCTAssertEqualObjects([simulators[3] name], @"iPad 3");
  XCTAssertEqual([simulators[3] state], FBSimulatorStateCreating);
  XCTAssertEqual([simulators[3] pool], self.pool);

  XCTAssertEqualObjects([simulators[4] name], @"iPhone 6S");
  XCTAssertEqual([simulators[4] state], FBSimulatorStateShuttingDown);
  XCTAssertEqual([simulators[4] pool], self.pool);

  XCTAssertEqualObjects([simulators[5] name], @"iPhone 5");
  XCTAssertEqual([simulators[5] state], FBSimulatorStateBooted);
  XCTAssertEqual([simulators[5] pool], self.pool);

  XCTAssertEqualObjects([simulators[6] name], @"iPhone 5");
  XCTAssertEqual([simulators[6] state], FBSimulatorStateShutdown);
  XCTAssertEqual([simulators[6] pool], self.pool);

  XCTAssertEqualObjects([simulators[7] name], @"iPad");
  XCTAssertEqual([simulators[7] state], FBSimulatorStateBooted);
  XCTAssertEqual([simulators[7] pool], self.pool);
}

- (void)testDividesAllocatedAndUnAllocated
{
  NSArray *mockedSimulators = [self createPoolWithExistingSimDeviceSpecs:@[
    @{@"name" : @"iPad 2", @"state" : @(FBSimulatorStateBooted)},
    @{@"name" : @"iPhone 5", @"state" : @(FBSimulatorStateCreating)},
    @{@"name" : @"iPhone 5", @"state" : @(FBSimulatorStateShutdown)},
    @{@"name" : @"iPad 3", @"state" : @(FBSimulatorStateCreating)},
    @{@"name" : @"iPhone 6S", @"state" : @(FBSimulatorStateShuttingDown) },
    @{@"name" : @"iPhone 5", @"state" : @(FBSimulatorStateBooted)},
    @{@"name" : @"iPhone 5", @"state" : @(FBSimulatorStateShutdown)},
    @{@"name" : @"iPad", @"state" : @(FBSimulatorStateBooted)}
  ]];

  [self mockAllocationOfSimulatorsUDIDs:@[
    [mockedSimulators[0] UDID],
    [mockedSimulators[3] UDID]
  ]];

  NSOrderedSet *simulators = self.pool.allocatedSimulators;
  XCTAssertEqual(simulators.count, 2);

  XCTAssertEqualObjects([simulators[0] name], @"iPad 2");
  XCTAssertEqual([simulators[0] state], FBSimulatorStateBooted);
  XCTAssertEqual([simulators[0] pool], self.pool);

  XCTAssertEqualObjects([simulators[1] name], @"iPad 3");
  XCTAssertEqual([simulators[1] state], FBSimulatorStateCreating);
  XCTAssertEqual([simulators[1] pool], self.pool);

  simulators = self.pool.unallocatedSimulators;
  XCTAssertEqual(simulators.count, 6);

  XCTAssertEqualObjects([simulators[0] name], @"iPhone 5");
  XCTAssertEqual([simulators[0] state], FBSimulatorStateCreating);
  XCTAssertEqual([simulators[0] pool], self.pool);

  XCTAssertEqualObjects([simulators[1] name], @"iPhone 5");
  XCTAssertEqual([simulators[1] state], FBSimulatorStateShutdown);
  XCTAssertEqual([simulators[1] pool], self.pool);

  XCTAssertEqualObjects([simulators[2] name], @"iPhone 6S");
  XCTAssertEqual([simulators[2] state], FBSimulatorStateShuttingDown);
  XCTAssertEqual([simulators[2] pool], self.pool);

  XCTAssertEqualObjects([simulators[3] name], @"iPhone 5");
  XCTAssertEqual([simulators[3] state], FBSimulatorStateBooted);
  XCTAssertEqual([simulators[3] pool], self.pool);

  XCTAssertEqualObjects([simulators[4] name], @"iPhone 5");
  XCTAssertEqual([simulators[4] state], FBSimulatorStateShutdown);
  XCTAssertEqual([simulators[4] pool], self.pool);

  XCTAssertEqualObjects([simulators[5] name], @"iPad");
  XCTAssertEqual([simulators[5] state], FBSimulatorStateBooted);
  XCTAssertEqual([simulators[5] pool], self.pool);
}

@end
