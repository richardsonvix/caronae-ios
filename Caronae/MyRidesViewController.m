#import "MyRidesViewController.h"
#import "Ride.h"
#import "CaronaeRideCell.h"
#import "RideViewController.h"

@interface MyRidesViewController () <RideDelegate>
@property (nonatomic) NSArray *rides;
@property (nonatomic) Ride *selectedRide;
@property (nonatomic) NSDictionary *user;
@end

@implementation MyRidesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UINib *cellNib = [UINib nibWithNibName:@"CaronaeRideCell" bundle:nil];
    [self.tableView registerNib:cellNib forCellReuseIdentifier:@"Ride Cell"];
    
    self.tableView.estimatedRowHeight = 100.0;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"NavigationBarLogo"]];
    
    self.user = [CaronaeDefaults defaults].user;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveNotification:) name:CaronaeUserRidesUpdatedNotification object:nil];
    
    [self updateRides];
}

- (void)updateRides {
    // TODO: Add to secondary thread?
    NSArray *rideArchive = [[NSUserDefaults standardUserDefaults] objectForKey:@"userCreatedRides"];
    NSMutableArray *rides = [[NSMutableArray alloc] initWithCapacity:rideArchive.count];
    for (id rideDictionary in rideArchive) {
        Ride *ride = [[Ride alloc] initWithDictionary:rideDictionary];
        
        // Skip rides in the past
        if ([ride.date compare:[NSDate date]] == NSOrderedAscending) {
            continue;
        }
        
        ride.driverID = self.user[@"id"];
        ride.driverName = self.user[@"name"];
        ride.driverCourse = self.user[@"course"];
        [rides addObject:ride];
    }
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:YES];
    _rides = [rides sortedArrayUsingDescriptors:@[sortDescriptor]];
}

- (void)didReceiveNotification:(NSNotification *)notification {
    if ([notification.name isEqualToString:CaronaeUserRidesUpdatedNotification]) {
        [self updateRides];
        [self.tableView reloadData];
    }
}

#pragma mark - Ride methods

- (void)didDeleteRide:(Ride *)ride {
    NSLog(@"User has deleted ride with id %ld", ride.rideID);
    
    // Find and delete ride from persistent store
    NSMutableArray *newRides = [[[NSUserDefaults standardUserDefaults] objectForKey:@"userCreatedRides"] mutableCopy];
    for (NSDictionary *r in newRides) {
        if ([r[@"rideId"] longValue] == ride.rideID || [r[@"id"] longValue] == ride.rideID) {
            [newRides removeObject:r];
            break;
        }
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:newRides forKey:@"userCreatedRides"];
    
    NSInteger deletedIndex = [_rides indexOfObject:ride];
    if (deletedIndex == NSNotFound) {
        NSLog(@"Error: ride to be deleted was not found in user's rides");
        return;
    }

    [self updateRides];
    
    // Update view
    [self.tableView beginUpdates];
    [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:deletedIndex inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView endUpdates];
}


#pragma mark - Table methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.rides.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CaronaeRideCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Ride Cell" forIndexPath:indexPath];
    
    [cell configureCellWithRide:self.rides[indexPath.row]];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    self.selectedRide = self.rides[indexPath.row];
    [self performSegueWithIdentifier:@"ViewRideDetails" sender:self];
}


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"ViewRideDetails"]) {
        RideViewController *vc = segue.destinationViewController;
        vc.ride = self.selectedRide;
        vc.delegate = self;
    }
}

@end
