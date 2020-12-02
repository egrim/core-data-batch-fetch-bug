//
//  CustomIncrementalStore.m
//  coreDataBatchFetchBugObjC
//
//  Created by Evan Grim on 12/1/20.
//

#import "CustomIncrementalStore.h"

NSString *const CustomeIncrementalStoreType = @"CustomIncrementalStore";


@implementation CustomIncrementalStore

+(void)load {
    [NSPersistentStoreCoordinator registerStoreClass:[CustomIncrementalStore class] forStoreType:CustomeIncrementalStoreType];
}

-(instancetype)initWithPersistentStoreCoordinator:(NSPersistentStoreCoordinator *)root configurationName:(NSString *)name URL:(NSURL *)url options:(NSDictionary *)options {
    self = [super initWithPersistentStoreCoordinator:root configurationName:name URL:url options:options];
    if (self) {
        self.entities = [[NSMutableSet alloc] init];
    }
    return self;
}

- (BOOL)loadMetadata:(NSError *__autoreleasing  _Nullable *)error {
    return YES;
}

-(id)executeRequest:(NSPersistentStoreRequest *)request withContext:(NSManagedObjectContext *)context error:(NSError *__autoreleasing  _Nullable *)error {
    if (request.requestType == NSSaveRequestType) {
        NSSaveChangesRequest *saveChangesRequest = (NSSaveChangesRequest *)request;
        [self.entities unionSet:saveChangesRequest.insertedObjects];
        [self.entities unionSet:saveChangesRequest.updatedObjects];
        [self.entities minusSet:saveChangesRequest.deletedObjects];
        return @[];
    } else if (request.requestType == NSFetchRequestType){
        NSFetchRequest *fetchRequest = (NSFetchRequest *)request;
        NSPredicate *predicate = fetchRequest.predicate;
        NSSet<NSManagedObject *> *resultSet = predicate == nil ? [self.entities copy] : [self.entities filteredSetUsingPredicate:fetchRequest.predicate];
        switch (fetchRequest.resultType) {
            case NSCountResultType:
                return @[@(resultSet.count)];

            case NSManagedObjectResultType:
                return [resultSet allObjects];
                
            case NSManagedObjectIDResultType:
                return [[resultSet allObjects] valueForKey:@"objectID"];
                
            default:
                return nil;
        }
    }
    return nil;
}

@end
