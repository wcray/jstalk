//
//  JSTBridgeType.m
//  jstalk
//
//  Created by August Mueller on 9/15/10.
//  Copyright 2010 Flying Meat Inc. All rights reserved.
//

#import "JSTRuntimeInfo.h"
#import "JSCocoaFFIArgument.h"
#import <objc/runtime.h>

@implementation JSTRuntimeInfo

@synthesize objectType=_objectType;
@synthesize symbolName=_symbolName;
@synthesize typeEncoding=_typeEncoding;
@synthesize declaredType=_declaredType;
@synthesize enumValue=_enumValue;
@synthesize returnValue=_returnValue;
@synthesize methodSelector=_methodSelector;


- (void)dealloc {
    [_symbolName release];
    [_typeEncoding release];
    [_structFields release];
    [_declaredType release];
    [_arguments release];
    [_returnValue release];
    [_methodSelector release];
    [_instanceMethods release];

    [super dealloc];
}

- (NSArray *)structFields {
    return _structFields;
}

- (void)addStructField:(NSString*)s {
    if (!_structFields) {
        _structFields = [[NSMutableArray alloc] init];
    }
    
    [_structFields addObject:s];
}

- (NSArray *)arguments {
    return _arguments;
}
- (void)addArgument:(JSTRuntimeInfo*)arg {
    if (!_arguments) {
        _arguments = [[NSMutableArray alloc] init];
    }
    
    [_arguments addObject:arg];
}



- (NSDictionary *)instanceMethods {
    return _instanceMethods;
}

- (void)addInstanceMethod:(JSTRuntimeInfo*)arg {
    if (!_instanceMethods) {
        _instanceMethods = [[NSMutableDictionary alloc] init];
    }
    
    [_instanceMethods setObject:arg forKey:[arg methodSelector]];
}


- (NSDictionary *)classMethods {
    return _classMethods;
}

- (void)addClassMethod:(JSTRuntimeInfo*)arg {
    if (!_classMethods) {
        _classMethods = [[NSMutableDictionary alloc] init];
    }
    
    [_classMethods setObject:arg forKey:[arg methodSelector]];
}

- (void)grabTypeFromAttributes:(NSDictionary*)atts {
    
#if defined(__x86_64__)
    if ([atts objectForKey:@"type64"]) {
        [self setTypeEncoding:[atts objectForKey:@"type64"]];
    }
    else
#endif
    {
        [self setTypeEncoding:[atts objectForKey:@"type"]];
    }
}

- (JSCocoaFFIArgument*)ffiArgumentForRuntimeInfo:(JSTRuntimeInfo *)arg {
    
    NSString *typeEncoding                  = [arg typeEncoding];
    char typeEncodingChar                   = [typeEncoding UTF8String][0];
    JSCocoaFFIArgument *argumentEncoding    = [[[JSCocoaFFIArgument alloc] init] autorelease];
    
    if (typeEncodingChar == '{') {
        [argumentEncoding setStructureTypeEncoding:typeEncoding];
    }
    else if (typeEncodingChar == '^') {
        
        // Special case for functions like CGColorSpaceCreateWithName
        if ([typeEncoding isEqualToString:@"^{__CFString=}"]) {
            [argumentEncoding setTypeEncoding:_C_ID];
        }
        else {
            [argumentEncoding setPointerTypeEncoding:typeEncoding];
        }
    }
    else {
        BOOL didSet = [argumentEncoding setTypeEncoding:typeEncodingChar];
        if (!didSet) {
            NSLog(@"%s:%d", __FUNCTION__, __LINE__);
            NSLog(@"Could not set type encoding");
            return nil;
        }
    }
    
    return argumentEncoding;
}

- (NSArray*)functionEncodings {
    
    NSMutableArray *argumentEncodings = [NSMutableArray array];
    
    JSTRuntimeInfo *returnInfo = [self returnValue];
    
    JSCocoaFFIArgument *ffia;
    
    if (!returnInfo) {
        ffia = [[[JSCocoaFFIArgument alloc] init] autorelease];
        [ffia setTypeEncoding:'v'];
    }
    else {
        ffia = [self ffiArgumentForRuntimeInfo:returnInfo];
    }
    
    [ffia setIsReturnValue:YES];
    [argumentEncodings addObject:ffia];
    
    for (JSTRuntimeInfo *arg in [self arguments]) {
        [argumentEncodings addObject:[self ffiArgumentForRuntimeInfo:arg]];
    }
    
    return argumentEncodings;
}






@end
