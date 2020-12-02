//
//  CustomIncrementalStore.h
//  coreDataBatchFetchBugObjC
//
//  Created by Evan Grim on 12/1/20.
//

#import <CoreData/CoreData.h>

extern NSString *const CustomeIncrementalStoreType;


@interface CustomIncrementalStore : NSIncrementalStore

@property NSMutableSet<NSManagedObject *> *entities;

@end
