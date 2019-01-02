//
//  CEBaseYYModel.h
//  CarEagleInspector
//
//  Created by JunhuaShao on 2018/9/4.
//  Copyright © 2018年 CarEagle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <MagicalRecord/MagicalRecord.h>

#import <YYModel.h>

@protocol CEYYModelCoreData <NSObject>
// 关联NSManagedObjectEntity的名字
+ (NSString *)managedObjectEntityName;
// 指明 NSManagedObjectEntity 中表示关系的字段
+ (NSDictionary <NSString *, id> *)managedRelationshipPropertyMapper;
// 指明 NSManagedObjectEntity 中集合字段的类型
+ (NSDictionary <NSString *, id> *)managedRelationshipContainerPropertyMapper;
@end

@interface CEBaseYYModel : NSObject <YYModel, NSCopying, NSCoding, CEYYModelCoreData>

#pragma mark CoreData
@property (strong, nonatomic) NSString *uuid;

+ (NSString *)managedObjectEntityName;

- (void)setValuesByManagedObj:(NSManagedObject *)obj;
- (NSManagedObject *)managedObj;

- (void)updateValueFromDB;
- (void)DBDelete;
- (void)DBSave;

- (NSString *)md5String;

@end
