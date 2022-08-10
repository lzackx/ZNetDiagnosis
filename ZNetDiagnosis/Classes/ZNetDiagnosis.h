//
//  ZNetDiagnosis.h
//  ZNetDiagnosis
//
//  Created by lZackx on 2022/8/3.
//

#import <Foundation/Foundation.h>

#import "ZNetDiagnosisDefined.h"


NS_ASSUME_NONNULL_BEGIN

@interface ZNetDiagnosis : NSObject

+ (instancetype)shared;

- (void)addOperation:(NSOperation *)operation;

@end

NS_ASSUME_NONNULL_END
