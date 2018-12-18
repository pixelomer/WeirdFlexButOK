#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import "Extensions/NSString+Random.h"
#if DEBUG
#define NSLog(args...) NSLog(@"[WFBOK] "args)
#else
#define NSLog(...); /* */
#endif

#define WeirdFlexUnit_MAX 2
#define WeirdFlexUnit_MIN 1
#define WeirdFlexUnit_ReturnOverrideWithConstant @1
#define WeirdFlexUnit_ArgumentOverride @2
#define kUnitType @"UnitType"
#define kArguments @"Arguments"
#define kEncodedArgType @"Type"
#define kValue @"Value"
#define kIsInstanceMethod @"IsInstanceMethod"
#define kFilter @"!Filter"
#define WeirdFlexPatchRoot @"/Library/WeirdFlexButOK"

#if 0
#define kDoesReturn @"DoesReturn"
#endif

static NSDictionary *humanReadableStrings;
static const char *EncodedTypeFromHumanReadableNSString(NSString *humanReadableString) {
	const char *defaultType = "?";
	if (!humanReadableString) return defaultType;
	NSString *encodedString = [humanReadableStrings objectForKey:[humanReadableString lowercaseString]];
	NSLog(@"%@", encodedString);
	return ((encodedString != NULL) ? [encodedString UTF8String] : defaultType);
}
static void ConvertNSObjectToEncodedCType(id object, const char *encodedType, void **pt) {
	NSLog(@"ConvertNSObjectToEncodedCType(%@, %s)", object, encodedType);
	if (object != NULL) {
		void *newObj = NULL;
		unsigned int newObjSize = 0;
		#define CheckWithReferenceSelector(typeToCheck, selector) \
NSLog(@"Definition being used: CheckWithReferenceSelector(\"%s\", \"%s\")", #typeToCheck, #selector); \
if (strcmp(encodedType, @encode(typeToCheck)) == 0) { \
	NSLog(@"Match!"); \
	newObj = new typeToCheck; \
	typeToCheck value = (typeToCheck)[(NSNumber *)object selector]; \
	newObjSize = sizeof value; \
	*(typeToCheck*)newObj = value; \
	NSLog(@"Size: %i", newObjSize); \
	NSLog(@"New object pointer is NULL: %i", newObj == NULL); \
	goto end; \
} else
		#define RealNumberCheck(typeToCheck) CheckWithReferenceSelector(typeToCheck, doubleValue)
		#define IntegerNumberCheck(typeToCheck) CheckWithReferenceSelector(typeToCheck, longLongValue)
		#define UIntegerNumberCheck(typeToCheck) CheckWithReferenceSelector(typeToCheck, unsignedLongLongValue)
		if (strcmp(encodedType, @encode(id)) == 0) *pt = object;
		else if ([object isKindOfClass:[NSNumber class]]) {
			IntegerNumberCheck(bool)
			IntegerNumberCheck(char)
			RealNumberCheck(double)
			RealNumberCheck(float)
			IntegerNumberCheck(int)
			IntegerNumberCheck(long long)
			IntegerNumberCheck(long)
			IntegerNumberCheck(short)
			UIntegerNumberCheck(unsigned char)
			UIntegerNumberCheck(unsigned int)
			UIntegerNumberCheck(unsigned long long)
			UIntegerNumberCheck(unsigned long)
			UIntegerNumberCheck(unsigned short);
		end:
			NSLog(@"Integer conversion completed");
		}
		else if ([object isKindOfClass:[NSString class]]) {
			if (strcmp(encodedType, @encode(char*))) {
				newObj = new char *;
				char *value = (char*)[(NSString *)object UTF8String];
				*(char**)newObj = value;
				newObjSize = strlen(value) + 1;
			}
		}
		if (newObj != NULL && newObjSize != 0) {
			NSLog(@"Copying memory with memcpy(pt, newObj, %i)", newObjSize);
			memcpy(pt, newObj, newObjSize);
		}
		#undef UIntegerNumberCheck
		#undef IntegerNumberCheck
		#undef RealNumberCheck
		#undef CheckWithReferenceSelector
	}
}

%ctor {
	NSLog(@"Init!");
	#define DictEntry(type) [@(#type) lowercaseString] : @(@encode(type))
	humanReadableStrings = @{
		DictEntry(id),
		DictEntry(bool),
		DictEntry(char),
		DictEntry(double),
		DictEntry(float),
		DictEntry(int),
		DictEntry(long long),
		DictEntry(long),
		DictEntry(short),
		DictEntry(unsigned char),
		DictEntry(CGFloat),
		DictEntry(unsigned int),
		DictEntry(unsigned long long),
		DictEntry(unsigned long),
		DictEntry(unsigned short)
	};
	#undef DictEntry
	NSFileManager *fm = [NSFileManager defaultManager]; // Pointer for easily accessing the default NSFileManager object
	NSArray<NSBundle*> *frameworks = NSBundle.allFrameworks;
	NSArray *fileList = [fm contentsOfDirectoryAtPath:WeirdFlexPatchRoot error:nil];
	if (!fileList) return; // If the tweak wasn't able to get the patch list, stop loading the tweak.
	for (NSString *filename in fileList) {
		if (![filename hasSuffix:@".plist"]) continue; // Every patch has to be a Property List file and have a ".plist" extension
		NSString *fullPath = [WeirdFlexPatchRoot stringByAppendingPathComponent:filename]; // Get the full path by appending the file to the WeirdFlex patch path
		NSDictionary *replacementDict = [NSDictionary dictionaryWithContentsOfFile:fullPath];
		if (!replacementDict) continue; // If the patch couldn't be loaded, go to the next file.
		id filterArr = [replacementDict objectForKey:kFilter]; // Get the filter for the patch. It has to contain bundle identifiers for frameworks and apps.
		if (!filterArr || ![filterArr isKindOfClass:[NSArray class]] || !([filterArr count] > 0)) continue; // The object has to be an array and it has to contain at least one bundle identifier
		bool usePatch = false;
		for (id bundle in (NSArray*)filterArr) {
			if (![bundle isKindOfClass:[NSString class]]) continue;
			if ([NSBundle.mainBundle.bundleIdentifier isEqualToString:bundle]) usePatch = true;
			for (NSBundle *fwbundle in frameworks) if ([[fwbundle bundleIdentifier] isEqualToString:bundle]) usePatch = true; // Check for frameworks as well.
			if (usePatch) break; // If there was a match, break out of the loop to prevent extra processing
		}
		if (!usePatch) continue;
		NSLog(@"File is being used: %@", filename);
		for (NSString *className in replacementDict) {
			if ([className hasPrefix:@"!"]) continue; // If the key has a "!" prefix, this means it's not actually a class name, it's a patch configuration key. Continue the loop with the next key.
			Class classObj = NSClassFromString(className);
			if (classObj != NULL) {
				id object = [replacementDict objectForKey:className]; // Get the units for a class
				if (![object isKindOfClass:[NSDictionary class]]) continue; // The units must be stored in a dictionary
				for (NSString *selectorString in object) {
					SEL selector = NSSelectorFromString(selectorString);
					if (selector != NULL) {
						id selectorContents = [object objectForKey:selectorString]; // Get more information about the unit
						if (![selectorContents isKindOfClass:[NSDictionary class]]) continue;
						id unitType = [(NSDictionary *)selectorContents objectForKey:kUnitType]; // Get the unit type.
						/* Valid unit types:
						 *  1) Return override with constant: Used for overriding the return value.
						 *  2) Argument override: Used for returning the value from the original implementation that is called with overridden arguments
						 * TODO:
						 *  3) Return override with different method: Will be used for overriding the return value with another method's return value.
						 */
						if (![unitType isKindOfClass:[NSNumber class]] ||
							[(NSNumber*)unitType intValue] > WeirdFlexUnit_MAX ||
							[(NSNumber*)unitType intValue] < WeirdFlexUnit_MIN) continue;
						id isInstanceMethod = [(NSDictionary *)selectorContents objectForKey:kIsInstanceMethod];
						Method method = NULL;
						if (!isInstanceMethod || ![isInstanceMethod isKindOfClass:[NSNumber class]]) isInstanceMethod = @YES;
						if ([isInstanceMethod isEqual:@NO]) method = class_getClassMethod(classObj, selector);
						else method = class_getInstanceMethod(classObj, selector);
						unsigned int argAmount = 0;
						if (method != NULL) argAmount = method_getNumberOfArguments(method);
						else continue;
						if (argAmount < 2) continue;
						char returnType[255];
						method_getReturnType(method, returnType, 255);
						NSLog(@"Selector Contents: %@\nReturn type (encoded): %s\nArgument amount (including invisible ones): %i", selectorContents, returnType, argAmount);
						if ([(NSNumber*)unitType isEqual:WeirdFlexUnit_ArgumentOverride]) {
							NSString *newSelectorString = [NSString stringWithFormat:@"%@%@", [NSString randomStringWithLength:8], NSStringFromSelector(selector)]; // Create a prefixed string version of the original selector
							SEL newSelector = NSSelectorFromString(newSelectorString); // Create a selector object
							if (!newSelector) continue;
							NSLog(@"New selector: %@", NSStringFromSelector(newSelector));
							unsigned int visibleArgAmount = argAmount - 2;
							if (visibleArgAmount == 0) continue;
							NSLog(@"Visible argument amount: %i", visibleArgAmount);
							id arguments = [(NSDictionary *)selectorContents objectForKey:kArguments];
							if (!arguments || ![arguments isKindOfClass:[NSDictionary class]]) continue;
							NSLog(@"Arguments: %@", arguments);
							NSMutableArray *objects = [[NSMutableArray alloc] init];
							NSMutableArray *encodedVisibleMethodArgs = [[NSMutableArray alloc] init];
							bool shouldSkip = false;
							for (int i = 0; i < visibleArgAmount; i++) {
								NSString *argKey = [NSString stringWithFormat:@"arg%i", i+1];
								id argContents = [arguments objectForKey:argKey];
								if (!argContents || ![argContents isKindOfClass:[NSDictionary class]]) {
									NSLog(@"Error while processing the arguments. i=%i, argContents=%@", i, argContents);
									shouldSkip = true;
									break;
								}
								id objToReturn = [(NSDictionary *)argContents objectForKey:kValue];
								if (!objToReturn) objToReturn = [NSNull null];
								[objects addObject:objToReturn];
								NSString *encodedArgType = [(NSDictionary *)argContents objectForKey:kEncodedArgType];
								[encodedVisibleMethodArgs addObject:(encodedArgType ? @(EncodedTypeFromHumanReadableNSString(encodedArgType)) : @(@encode(id)))];
							}
							if (shouldSkip) continue;
							NSLog(@"%@, %@", encodedVisibleMethodArgs, objects);
							NSString *encodedVisibleMethodArgsString = [encodedVisibleMethodArgs componentsJoinedByString:@""];
							const char *encodedMethodType = [[NSString stringWithFormat:@"%s%s%s%@", returnType, @encode(id), @encode(SEL), encodedVisibleMethodArgsString] UTF8String];
							NSLog(@"\"%@\" -> \"%@\" (%s)", NSStringFromSelector(selector), NSStringFromSelector(newSelector), encodedMethodType);
							NSMethodSignature *sig = [[NSMethodSignature signatureWithObjCTypes:encodedMethodType] retain];
							if (!sig) continue;
							NSInvocation *inv = [[NSInvocation invocationWithMethodSignature:sig] retain];
							inv.selector = newSelector;
							int argsArrLength = [encodedVisibleMethodArgs count];
							for (int i = 0; i < argsArrLength; i++) {
								id object = [objects objectAtIndex:i];
								if (object && object != [NSNull null]) {
									const char *encodedTypeForObj = [[encodedVisibleMethodArgs objectAtIndex:i] UTF8String];
									void *finalObjectPt = NULL;
									ConvertNSObjectToEncodedCType(object, encodedTypeForObj, &finalObjectPt);
									NSLog(@"Setting argument %i...", i+2);
									[inv setArgument:&finalObjectPt atIndex:(i + 2)];
								}
							}
							//id functionReturns = [(NSDictionary *)selectorContents objectForKey:kDoesReturn];
							BOOL doesReturn = (strcmp(returnType, @encode(void)) != 0);
							//if (functionReturns && [functionReturns isKindOfClass:[NSNumber class]] && [functionReturns boolValue]) doesReturn = true;
							//else doesReturn = false;
							IMP newImplementation = NULL;
							if (doesReturn) {
								newImplementation = imp_implementationWithBlock(^void *(id self, SEL _cmd) {
									inv.target = self;
									NSLog(@"\"%@\" got called, invoking the original implementation...", newSelectorString);
									[inv invoke];
									NSLog(@"Getting buffer length...");
									NSUInteger length = [[inv methodSignature] methodReturnLength];
									NSLog(@"Creating buffer with length: %lu", length);
									void *buffer = malloc(length);
									NSLog(@"Filling buffer...");
									[inv getReturnValue:&buffer];
									return buffer;
								});
							}
							else {
								newImplementation = imp_implementationWithBlock(^void (id self, SEL _cmd) {
									inv.target = self;
									NSLog(@"\"%@\" got called, invoking the original implementation...", newSelectorString);
									[inv invoke];
								});
							}
							IMP oldImplementation = class_replaceMethod(classObj, selector, newImplementation, [[NSString stringWithFormat:@"%s%s%s", doesReturn ? @encode(void *) : @encode(void), @encode(id), @encode(SEL)] UTF8String]);
							if (oldImplementation == NULL) {
								NSLog(@"Failed to get the original implementation for selector: \"%@\". Aborting.", NSStringFromSelector(selector));
								abort();
							}
							class_addMethod(classObj, newSelector, oldImplementation, encodedMethodType);
						}
						else if ([(NSNumber*)unitType isEqual:WeirdFlexUnit_ReturnOverrideWithConstant]) {
							id newObject = [selectorContents objectForKey:kValue];
							if (!newObject) continue;
							[newObject retain];
							IMP newImplementation = imp_implementationWithBlock(^id(id self, SEL _cmd) {
								return newObject;
							});
							class_replaceMethod(classObj, selector, newImplementation, [[NSString stringWithFormat:@"%s%s%s", @encode(id), @encode(id), @encode(SEL)] UTF8String]);
						}
					}
				}
			}
		}
	}
}