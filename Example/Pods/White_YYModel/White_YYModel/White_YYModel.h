//
//  YYModel.h
//  YYModel <https://github.com/ibireme/YYModel>
//
//  Created by ibireme on 15/5/10.
//  Copyright (c) 2015 ibireme.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <Foundation/Foundation.h>

#if __has_include(<White_YYModel/White_YYModel.h>)
FOUNDATION_EXPORT double White_YYModelVersionNumber;
FOUNDATION_EXPORT const unsigned char YYModelVersionString[];
#import <White_YYModel/NSObject+White_YYModel.h>
#import <White_YYModel/White_YYClassInfo.h>
#else
#import "NSObject+White_YYModel.h"
#import "White_YYClassInfo.h"
#endif
