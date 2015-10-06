/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

@class FBSimulatorApplication;
@class FBSimulatorConfiguration;
@class FBSimulatorPool;
@class SimDevice;

/**
 The Default timeout for waits.
 */
extern NSTimeInterval const FBSimulatorDefaultTimeout;

/**
 Uses the known values of SimDevice State, to construct an enumeration.
 These mirror the values from -[SimDeviceState state].
 */
typedef NS_ENUM(NSInteger, FBSimulatorState) {
  FBSimulatorStateCreating = 0,
  FBSimulatorStateShutdown = 1,
  FBSimulatorStateBooting = 2,
  FBSimulatorStateBooted = 3,
  FBSimulatorStateShuttingDown = 4,
  FBSimulatorStateUnknown = -1,
};

/**
 Defines the High-Level Properties and Methods that exist on any Simulator returned from `FBSimulatorPool`.
 */
@interface FBSimulator : NSObject

/**
 The Underlying SimDevice.
 */
@property (nonatomic, strong, readonly) SimDevice *device;

/**
 Whether the Simulator is allocated or not.
 */
@property (nonatomic, assign, readonly, getter=isAllocated) BOOL allocated;

/**
 The Pool to which the Simulator Belongs.
 */
@property (nonatomic, weak, readonly) FBSimulatorPool *pool;

/**
 The Name of the allocated Simulator.
 */
@property (nonatomic, copy, readonly) NSString *name;

/**
 The UDID of the allocated Simulator.
 */
@property (nonatomic, copy, readonly) NSString *udid;

/**
 The State of the allocated Simulator.
 */
@property (nonatomic, assign, readonly) FBSimulatorState state;

/**
 The Process Identifier of the Simulator. -1 if it is not running
 */
@property (nonatomic, assign, readonly) NSInteger processIdentifier;

/**
 The Directory that Contains the Simulator's Data
 */
@property (nonatomic, copy, readonly) NSString *dataDirectory;

/**
 The Path to this Simulator's launchd_sim plist. Returns nil if the path does not exist.
 Expected to return a path when the Simulator is in the Booted state.
 */
@property (nonatomic, copy, readonly) NSString *launchdBootstrapPath;

/**
 The Process Identifier of the Simulator's launchd_sim. -1 if it is not running
 */
@property (nonatomic, assign, readonly) NSInteger launchdSimProcessIdentifier;

/**
 The Application that the Simulator should be launched with.
 */
@property (nonatomic, copy, readonly) FBSimulatorApplication *simulatorApplication;

/**
 The FBSimulatorConfiguration representing this Simulator.
 */
@property (nonatomic, copy, readonly) FBSimulatorConfiguration *configuration;

/**
 Synchronously waits on the provided state.

 @param state the state to wait on
 @returns YES if the Simulator transitioned to the given state with the default timeout, NO otherwise
 */
- (BOOL)waitOnState:(FBSimulatorState)state;

/**
 Synchronously waits on the provided state.

 @param state the state to wait on
 @param the timeout
 @returns YES if the Simulator transitioned to the given state with the timeout, NO otherwise
 */
- (BOOL)waitOnState:(FBSimulatorState)state timeout:(NSTimeInterval)timeout;

/**
 Convenience method for obtaining a description of Simulator State
 */
+ (NSString *)stateStringFromSimulatorState:(FBSimulatorState)state;

/**
 Convenience method for obtaining SimulatorState from a String.
 */
+ (FBSimulatorState)simulatorStateFromStateString:(NSString *)stateString;

/**
 Calls `freeSimulator:error:` on this device's pool, with the reciever as the first argument.

 @param error an error out for any error that occured.
 @returns YES if the freeing of the device was successful, NO otherwise.
 */
- (BOOL)freeFromPoolWithError:(NSError **)error;

@end
