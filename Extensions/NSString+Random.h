#import <Foundation/Foundation.h>

@interface NSString (Random)

+ (NSString *)randomStringWithLength:(int)len letters:(NSString*)letters;
+ (NSString *)randomStringWithLength:(int)len;
+ (NSString *)defaultRandomStringLetters;

@end