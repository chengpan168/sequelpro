//
//  $Id$
//
//  FLXPostgresConnectionTypeHandling.m
//  PostgresKit
//
//  Created by Stuart Connolly (stuconnolly.com) on July 29, 2012.
//  Copyright (c) 2012 Stuart Connolly. All rights reserved.
// 
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not 
//  use this file except in compliance with the License. You may obtain a copy of 
//  the License at
// 
//  http://www.apache.org/licenses/LICENSE-2.0
// 
//  Unless required by applicable law or agreed to in writing, software 
//  distributed under the License is distributed on an "AS IS" BASIS, WITHOUT 
//  WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the 
//  License for the specific language governing permissions and limitations under
//  the License.

#import "FLXPostgresConnectionTypeHandling.h"
#import "FLXPostgresTypeStringHandler.h"
#import "FLXPostgresTypeNumberHandler.h"
#import "FLXPostgresException.h"

@implementation FLXPostgresConnection (FLXPostgresConnectionTypeHandling)

/**
 * Register all of our data type handlers for this connection.
 */
- (void)registerTypeHandlers 
{
	if (_typeMap) {
		[_typeMap release];
		
		_typeMap = [[NSMutableDictionary alloc] init];
	}
	
	[self registerTypeHandler:[FLXPostgresTypeStringHandler class]];
	[self registerTypeHandler:[FLXPostgresTypeNumberHandler class]];	
}

/**
 * Get the data type handler for the supplied class.
 *
 * @param class The class to get the handler for.
 *
 * @return The handler or nil if there's none associated with the class.
 */
- (id <FLXPostgresTypeHandlerProtocol>)typeHandlerForClass:(Class)class 
{
	return [_typeMap objectForKey:NSStringFromClass(class)];
}

/**
 * Get the data type handler for the supplied PostgreSQL type.
 *
 * @param type The PostgreSQL type to get the handler for.
 *
 * @return The handler or nil if there's none associated with the type.
 */
- (id <FLXPostgresTypeHandlerProtocol>)typeHandlerForRemoteType:(FLXPostgresOid)type 
{		
	return [_typeMap objectForKey:[NSNumber numberWithUnsignedInteger:type]];
}

/**
 * Register the supplied type handler class.
 *
 * @param handlerClass The handler class to register.
 */
- (void)registerTypeHandler:(Class)handlerClass 
{		
	if (![handlerClass conformsToProtocol:@protocol(FLXPostgresTypeHandlerProtocol)]) {
		[FLXPostgresException raise:FLXPostgresConnectionErrorDomain 
							 reason:@"Class '%@' does not conform to protocol '%@'", NSStringFromClass(handlerClass), NSStringFromProtocol(@protocol(FLXPostgresTypeHandlerProtocol))];
	}
	
	// Create an instance of this class
	id <FLXPostgresTypeHandlerProtocol> handler = [[[handlerClass alloc] initWithConnection:self] autorelease];
	
	// Add to the type map - for native class
	[_typeMap setObject:handler forKey:NSStringFromClass([handler nativeClass])];
	
	NSArray *aliases = [handler classAliases];
	
	if (aliases) {
		for (NSString *alias in aliases)
		{
			[_typeMap setObject:handler forKey:alias];
		}
	}
	
	FLXPostgresOid *remoteTypes = [handler remoteTypes];
	
	for (NSUInteger i = 0; remoteTypes[i]; i++) 
	{		
		NSNumber *key = [NSNumber numberWithUnsignedInteger:remoteTypes[i]];
		
		[_typeMap setObject:handler forKey:key];
	}
}

@end
