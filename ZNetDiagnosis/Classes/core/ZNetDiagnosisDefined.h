//
//  ZNetDiagnosisDefined.h
//  ZNetDiagnosis
//
//  Created by lZackx on 2022/8/8.
//

#ifndef ZNetDiagnosisDefined_h
#define ZNetDiagnosisDefined_h

//#define ZND_DEBUG 1

#if ZND_DEBUG
#define ZLog(s, ...) NSLog(@"[ZAPM]: %@", [NSString stringWithFormat:(s), ##__VA_ARGS__])
#else
#define ZLog(...)
#endif

#endif /* ZNetDiagnosisDefined_h */
