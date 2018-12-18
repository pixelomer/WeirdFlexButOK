#import "NSString+Random.h"

@implementation NSString(Random)

+ (NSString *)randomStringWithLength:(int)len letters:(NSString*)letters {
    NSMutableString *randomString = [NSMutableString stringWithCapacity:len];
    for (int i = 0; i < len; i++) {
        [randomString appendFormat:@"%C", [letters characterAtIndex:(arc4random_uniform([letters length]))]];
    }
    return randomString;
}

+ (NSString *)randomStringWithLength:(int)len {
    return [NSString randomStringWithLength:len letters:[NSString defaultRandomStringLetters]];
}

+ (NSString *)defaultRandomStringLetters {
    return @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
}

@end