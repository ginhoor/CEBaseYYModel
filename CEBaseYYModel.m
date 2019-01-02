//
//  CEBaseYYModel.m
//  CarEagleInspector
//
//  Created by JunhuaShao on 2018/9/4.
//  Copyright © 2018年 CarEagle. All rights reserved.
//

#import <NSString+MD5.h>

#import "CEBaseYYModel.h"
#import "CEFinancialCreditVehicle+CECoreData.h"

@implementation CEBaseYYModel

+ (NSString *)managedObjectEntityName
{
    return [NSString stringWithFormat:@"%@Managed",NSStringFromClass([self class])];
}

+ (NSDictionary <NSString *, id> *)managedRelationshipPropertyMapper
{
    return @{};
}

+ (NSDictionary <NSString *, id> *)managedRelationshipContainerPropertyMapper
{
    return @{};
}

- (NSString *)md5String
{
    NSString *json = [self yy_modelToJSONString];
    
    return [json md5HexDigest];
}

- (NSString *)uuid
{
    if (!_uuid) {
        NSString *newID = [[NSUUID UUID] UUIDString];
        _uuid = newID;
    }
    return _uuid;
}

- (NSManagedObject *)managedObj
{
    NSPredicate *filter = [NSPredicate predicateWithFormat:@"uuid = %@", self.uuid];
    
    Class ManagedClass = NSClassFromString([[self class] managedObjectEntityName]);
    
    NSManagedObject *managedObj;
    if ([ManagedClass respondsToSelector:@selector(MR_findFirstWithPredicate:)]) {
        managedObj = [ManagedClass performSelector:@selector(MR_findFirstWithPredicate:) withObject:filter];
    }
    if (!managedObj) {
        if ([ManagedClass respondsToSelector:@selector(MR_createEntityInContext:)]) {
            managedObj = [ManagedClass performSelector:@selector(MR_createEntityInContext:) withObject:[NSManagedObjectContext MR_defaultContext]];
        }
    }

    return managedObj;
}

- (void)updateValueFromDB
{
    NSManagedObject *obj = [self managedObj];

    if (obj) {
        [self setValuesByManagedObj:obj];
    }
}

- (void)DBDelete
{
    NSManagedObject *obj = [self managedObj];
    
    if (obj) {
        [obj MR_deleteEntity];
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
    }
}

- (void)DBSave
{
    NSDictionary *json = [self yy_modelToJSONObject];
    NSManagedObject *managedObj = [self managedObj];
    [managedObj MR_importValuesForKeysWithObject:json];
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];    
}

- (void)setValuesByManagedObj:(NSManagedObject *)obj
{
    // 获得Entity中的字段名
    NSArray *attributesKeys = [[[obj entity] attributesByName] allKeys];
    // 根据字段名获得对应值
    NSDictionary *attributeDic = [obj dictionaryWithValuesForKeys:attributesKeys];
    // 将值设置给Model
    [self yy_modelSetWithJSON:attributeDic];
    
    // 获得Entity的关联关系
    NSArray<NSString *> *relationshipsKeys = [[[obj entity] relationshipsByName] allKeys];
    // 判断关联关系是否存在
    if (relationshipsKeys.count > 0) {
        // 获取关联关系的对应转换
        NSDictionary *relationshipDic = [(id<CEYYModelCoreData>)[self class] managedRelationshipPropertyMapper];
        
        [relationshipsKeys enumerateObjectsUsingBlock:^(NSString * _Nonnull key, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([relationshipDic.allKeys containsObject:key]) {
                Class relationshipClass = relationshipDic[key];
                
                //判断是否为容器类型
                if ([relationshipClass isSubclassOfClass:[NSArray class]] ||
                    [relationshipClass isSubclassOfClass:[NSSet class]] ||
                    [relationshipClass isSubclassOfClass:[NSOrderedSet class]]
                    ) {
                    
                    // 获取关联关系中容器的对应转换
                    NSDictionary *relationshipContainerDic = [(id<CEYYModelCoreData>)[self class] managedRelationshipContainerPropertyMapper];
                    
                    if ([relationshipContainerDic.allKeys containsObject:key]) {
                        
                        Class relationshipContainerClass = relationshipContainerDic[key];
                        // 获得Entity中的容器内容
                        NSArray <NSManagedObject *> *managedObjList = [obj valueForKey:key];
                        // 将关系中的元素转换成对应类型
                        id result = [managedObjList bk_map:^id(NSManagedObject *managedObj) {
                            CEBaseYYModel *containerObj = [[relationshipContainerClass alloc] init];
                            [containerObj setValuesByManagedObj:managedObj];
                            
                            return containerObj;
                        }];

                        NSString *newKey = key;
                        //默认转换key为对应关系的Key，如果使用YYModel定义了kKey转换关系，则会被替换成YYModel中的Key
                        if ([self respondsToSelector:@selector(modelCustomPropertyMapper)]) {
                            NSDictionary *modelCustomPropertyMapper = [(id<YYModel>)[self class] modelCustomPropertyMapper];
                            if ([modelCustomPropertyMapper.allValues containsObject:key]) {
                                newKey = modelCustomPropertyMapper.allKeys[[modelCustomPropertyMapper.allValues indexOfObject:key]];
                            }
                        }
                        // 将转换好的元素设置到Model中
                        [self setValue:result forKey:newKey];
                    }
                } else {
                    // 从Entity中获取对应值设置给Model
                    NSManagedObject *managedObj = [obj valueForKey:key];
                    CEBaseYYModel *containerObj = [[relationshipClass alloc] init];
                    [containerObj setValuesByManagedObj:managedObj];
                    [self setValue:containerObj forKey:key];
                }
            }
        }];
    }
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [self yy_modelEncodeWithCoder:aCoder];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    return [self yy_modelInitWithCoder:aDecoder];
}

- (id)copyWithZone:(NSZone *)zone {
    return [self yy_modelCopy];
}

- (NSUInteger)hash {
    return [self yy_modelHash];
}

- (BOOL)isEqual:(id)object {
    return [self yy_modelIsEqual:object];
}

- (NSString *)description {
    return [self yy_modelDescription];
}

@end
