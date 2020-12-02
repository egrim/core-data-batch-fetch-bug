//
//  coreDataBatchFetchBugObjCTests.m
//  coreDataBatchFetchBugObjCTests
//
//  Created by Evan Grim on 11/20/20.
//

#import <XCTest/XCTest.h>
#import <CoreData/CoreData.h>

#import "CustomIncrementalStore.h"

NSString *const ENTITY_NAME = @"Entity";


@interface coreDataBatchFetchBugObjCTests : XCTestCase

@property NSManagedObjectModel *managedObjectModel;
@property NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property NSManagedObjectContext *rootContext;

@end

@implementation coreDataBatchFetchBugObjCTests

-(void)setUp {
    NSEntityDescription *entityDescription = [[NSEntityDescription alloc] init];
    entityDescription.name = ENTITY_NAME;
    
    self.managedObjectModel = [[NSManagedObjectModel alloc] init];
    self.managedObjectModel.entities = @[entityDescription];
    
    self.persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
    
    self.rootContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    self.rootContext.persistentStoreCoordinator = self.persistentStoreCoordinator;
}

-(void)childContextSaveToStoreFollowedByBatchFetch {
    NSManagedObjectContext *childContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    childContext.parentContext = self.rootContext;
    
    [NSEntityDescription insertNewObjectForEntityForName:ENTITY_NAME inManagedObjectContext:childContext];
    
    NSError *error;
    BOOL success = [childContext save:&error];
    XCTAssertTrue(success, @"Error saving childContext: %@", error);
    
    success = [self.rootContext save:&error];
    XCTAssertTrue(success, @"Error saving rootContext: %@", error);
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:ENTITY_NAME];
    request.fetchBatchSize = 20;
    
    NSArray<NSManagedObject *> *results = [childContext executeFetchRequest:request error:&error];
    XCTAssertNotNil(results, @"Error fetching: %@", error);
    XCTAssertEqual(results.count, 1);
    
    // Actually accessing the result object triggers the bug
    XCTAssertNoThrow(results[0], @"Error fetching result");
}

-(void)testSQLStoreType {
    NSURL *dirURL = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    NSURL *fileURL = [NSURL URLWithString:@"Store.sql" relativeToURL:dirURL];
    NSError *error;
    
    NSPersistentStore *store = [self.persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:fileURL options:nil error:&error];
    XCTAssertNotNil(store, @"Error loading store: %@", error);
    
    NSPersistentStoreCoordinator *psc = self.persistentStoreCoordinator;
    [self addTeardownBlock:^{
        NSError *error;
        [psc destroyPersistentStoreAtURL:fileURL withType:NSSQLiteStoreType options:nil error:&error];
        XCTAssertNil(error, @"Error tearing down persistent store:%@", error);
    }];
    
    [self childContextSaveToStoreFollowedByBatchFetch];
}

-(void)testBinaryStoreType {
    NSURL *dirURL = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    NSURL *fileURL = [NSURL URLWithString:@"Store.bin" relativeToURL:dirURL];
    NSError *error;
    
    NSPersistentStore *store = [self.persistentStoreCoordinator addPersistentStoreWithType:NSBinaryStoreType configuration:nil URL:fileURL options:nil error:&error];
    XCTAssertNotNil(store, @"Error loading store: %@", error);
    
    NSPersistentStoreCoordinator *psc = self.persistentStoreCoordinator;
    [self addTeardownBlock:^{
        NSError *error;
        [psc destroyPersistentStoreAtURL:fileURL withType:NSBinaryStoreType options:nil error:&error];
        XCTAssertNil(error, @"Error tearing down persistent store:%@", error);
    }];
    
    [self childContextSaveToStoreFollowedByBatchFetch];
}

-(void)testInMemoryStoreType {
    NSError *error;
    NSPersistentStore *store = [self.persistentStoreCoordinator addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:nil error:&error];
    XCTAssertNotNil(store, @"Error loading store: %@", error);
    [self childContextSaveToStoreFollowedByBatchFetch];
}


-(void)testCustomIncrementalStore {
    NSError *error;
    NSPersistentStore *store = [self.persistentStoreCoordinator addPersistentStoreWithType:CustomeIncrementalStoreType configuration:nil URL:nil options:nil error:&error];
    XCTAssertNotNil(store, @"Error loading store: %@", error);
    
    [self childContextSaveToStoreFollowedByBatchFetch];
}

@end
