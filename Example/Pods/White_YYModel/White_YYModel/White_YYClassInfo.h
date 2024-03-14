//
//  YYClassInfo.h
//  YYModel <https://github.com/ibireme/YYModel>
//
//  Created by ibireme on 15/5/9.
//  Copyright (c) 2015 ibireme.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Type encoding's type.
 */
typedef NS_OPTIONS(NSUInteger, White_YYEncodingType) {
    White_YYEncodingTypeMask       = 0xFF, ///< mask of type value
    White_YYEncodingTypeUnknown    = 0, ///< unknown
    White_YYEncodingTypeVoid       = 1, ///< void
    White_YYEncodingTypeBool       = 2, ///< bool
    White_YYEncodingTypeInt8       = 3, ///< char / BOOL
    White_YYEncodingTypeUInt8      = 4, ///< unsigned char
    White_YYEncodingTypeInt16      = 5, ///< short
    White_YYEncodingTypeUInt16     = 6, ///< unsigned short
    White_YYEncodingTypeInt32      = 7, ///< int
    White_YYEncodingTypeUInt32     = 8, ///< unsigned int
    White_YYEncodingTypeInt64      = 9, ///< long long
    White_YYEncodingTypeUInt64     = 10, ///< unsigned long long
    White_YYEncodingTypeFloat      = 11, ///< float
    White_YYEncodingTypeDouble     = 12, ///< double
    White_YYEncodingTypeLongDouble = 13, ///< long double
    White_YYEncodingTypeObject     = 14, ///< id
    White_YYEncodingTypeClass      = 15, ///< Class
    White_YYEncodingTypeSEL        = 16, ///< SEL
    White_YYEncodingTypeBlock      = 17, ///< block
    White_YYEncodingTypePointer    = 18, ///< void*
    White_YYEncodingTypeStruct     = 19, ///< struct
    White_YYEncodingTypeUnion      = 20, ///< union
    White_YYEncodingTypeCString    = 21, ///< char*
    White_YYEncodingTypeCArray     = 22, ///< char[10] (for example)
    
    White_YYEncodingTypeQualifierMask   = 0xFF00,   ///< mask of qualifier
    White_YYEncodingTypeQualifierConst  = 1 << 8,  ///< const
    White_YYEncodingTypeQualifierIn     = 1 << 9,  ///< in
    White_YYEncodingTypeQualifierInout  = 1 << 10, ///< inout
    White_YYEncodingTypeQualifierOut    = 1 << 11, ///< out
    White_YYEncodingTypeQualifierBycopy = 1 << 12, ///< bycopy
    White_YYEncodingTypeQualifierByref  = 1 << 13, ///< byref
    White_YYEncodingTypeQualifierOneway = 1 << 14, ///< oneway
    
    White_YYEncodingTypePropertyMask         = 0xFF0000, ///< mask of property
    White_YYEncodingTypePropertyReadonly     = 1 << 16, ///< readonly
    White_YYEncodingTypePropertyCopy         = 1 << 17, ///< copy
    White_YYEncodingTypePropertyRetain       = 1 << 18, ///< retain
    White_YYEncodingTypePropertyNonatomic    = 1 << 19, ///< nonatomic
    White_YYEncodingTypePropertyWeak         = 1 << 20, ///< weak
    White_YYEncodingTypePropertyCustomGetter = 1 << 21, ///< getter=
    White_YYEncodingTypePropertyCustomSetter = 1 << 22, ///< setter=
    White_YYEncodingTypePropertyDynamic      = 1 << 23, ///< @dynamic
};

/**
 Get the type from a Type-Encoding string.
 
 @discussion See also:
 https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html
 https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtPropertyIntrospection.html
 
 @param typeEncoding  A Type-Encoding string.
 @return The encoding type.
 */
White_YYEncodingType YYEncodingGetType(const char *typeEncoding);


/**
 Instance variable information.
 */
@interface White_YYClassIvarInfo : NSObject
@property (nonatomic, assign, readonly) Ivar ivar;              ///< ivar opaque struct
@property (nonatomic, strong, readonly) NSString *name;         ///< Ivar's name
@property (nonatomic, assign, readonly) ptrdiff_t offset;       ///< Ivar's offset
@property (nonatomic, strong, readonly) NSString *typeEncoding; ///< Ivar's type encoding
@property (nonatomic, assign, readonly) White_YYEncodingType type;    ///< Ivar's type

/**
 Creates and returns an ivar info object.
 
 @param ivar ivar opaque struct
 @return A new object, or nil if an error occurs.
 */
- (instancetype)initWithIvar:(Ivar)ivar;
@end


/**
 Method information.
 */
@interface White_YYClassMethodInfo : NSObject
@property (nonatomic, assign, readonly) Method method;                  ///< method opaque struct
@property (nonatomic, strong, readonly) NSString *name;                 ///< method name
@property (nonatomic, assign, readonly) SEL sel;                        ///< method's selector
@property (nonatomic, assign, readonly) IMP imp;                        ///< method's implementation
@property (nonatomic, strong, readonly) NSString *typeEncoding;         ///< method's parameter and return types
@property (nonatomic, strong, readonly) NSString *returnTypeEncoding;   ///< return value's type
@property (nullable, nonatomic, strong, readonly) NSArray<NSString *> *argumentTypeEncodings; ///< array of arguments' type

/**
 Creates and returns a method info object.
 
 @param method method opaque struct
 @return A new object, or nil if an error occurs.
 */
- (instancetype)initWithMethod:(Method)method;
@end


/**
 Property information.
 */
@interface White_YYClassPropertyInfo : NSObject
@property (nonatomic, assign, readonly) objc_property_t property; ///< property's opaque struct
@property (nonatomic, strong, readonly) NSString *name;           ///< property's name
@property (nonatomic, assign, readonly) White_YYEncodingType type;      ///< property's type
@property (nonatomic, strong, readonly) NSString *typeEncoding;   ///< property's encoding value
@property (nonatomic, strong, readonly) NSString *ivarName;       ///< property's ivar name
@property (nullable, nonatomic, assign, readonly) Class cls;      ///< may be nil
@property (nullable, nonatomic, strong, readonly) NSArray<NSString *> *protocols; ///< may nil
@property (nonatomic, assign, readonly) SEL getter;               ///< getter (nonnull)
@property (nonatomic, assign, readonly) SEL setter;               ///< setter (nonnull)

/**
 Creates and returns a property info object.
 
 @param property property opaque struct
 @return A new object, or nil if an error occurs.
 */
- (instancetype)initWithProperty:(objc_property_t)property;
@end


/**
 Class information for a class.
 */
@interface White_YYClassInfo : NSObject
@property (nonatomic, assign, readonly) Class cls; ///< class object
@property (nullable, nonatomic, assign, readonly) Class superCls; ///< super class object
@property (nullable, nonatomic, assign, readonly) Class metaCls;  ///< class's meta class object
@property (nonatomic, readonly) BOOL isMeta; ///< whether this class is meta class
@property (nonatomic, strong, readonly) NSString *name; ///< class name
@property (nullable, nonatomic, strong, readonly) White_YYClassInfo *superClassInfo; ///< super class's class info
@property (nullable, nonatomic, strong, readonly) NSDictionary<NSString *, White_YYClassIvarInfo *> *ivarInfos; ///< ivars
@property (nullable, nonatomic, strong, readonly) NSDictionary<NSString *, White_YYClassMethodInfo *> *methodInfos; ///< methods
@property (nullable, nonatomic, strong, readonly) NSDictionary<NSString *, White_YYClassPropertyInfo *> *propertyInfos; ///< properties

/**
 If the class is changed (for example: you add a method to this class with
 'class_addMethod()'), you should call this method to refresh the class info cache.
 
 After called this method, `needUpdate` will returns `YES`, and you should call 
 'classInfoWithClass' or 'classInfoWithClassName' to get the updated class info.
 */
- (void)setNeedUpdate;

/**
 If this method returns `YES`, you should stop using this instance and call
 `classInfoWithClass` or `classInfoWithClassName` to get the updated class info.
 
 @return Whether this class info need update.
 */
- (BOOL)needUpdate;

/**
 Get the class info of a specified Class.
 
 @discussion This method will cache the class info and super-class info
 at the first access to the Class. This method is thread-safe.
 
 @param cls A class.
 @return A class info, or nil if an error occurs.
 */
+ (nullable instancetype)classInfoWithClass:(Class)cls;

/**
 Get the class info of a specified Class.
 
 @discussion This method will cache the class info and super-class info
 at the first access to the Class. This method is thread-safe.
 
 @param className A class name.
 @return A class info, or nil if an error occurs.
 */
+ (nullable instancetype)classInfoWithClassName:(NSString *)className;

@end

NS_ASSUME_NONNULL_END
