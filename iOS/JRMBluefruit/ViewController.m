//
//  ViewController.m
//  JRMBluefruit
//
//  Created by Caroline on 4/21/16.
//  Copyright © 2016 Caroline Harrison. All rights reserved.
//

#import "ViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "JRMAudioPlayer.h"

#define RX_UUID @"6E400003-B5A3-F393-E0A9-E50E24DCCA9E"
#define TX_UUID @"6e400002-b5a3-f393-e0a9-e50e24dcca9e"

@interface ViewController () <CBCentralManagerDelegate, CBPeripheralDelegate>

@property (nonatomic, strong) CBCentralManager *centralManager;
@property (strong, nonatomic) CBPeripheral *currentPeripheral;
@property (strong, nonatomic) CBCharacteristic *transferCharacteristic;

@property (weak, nonatomic) IBOutlet UILabel *connectingLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UIButton *greenLedButton;

@property (strong, nonatomic) JRMAudioPlayer *audioPlayer;
@property (strong, nonatomic) NSNumberFormatter *numberFormatter;

@property BOOL greenLedLit;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    self.greenLedButton.hidden = YES;
    
    self.audioPlayer = [[JRMAudioPlayer alloc] init];
    [self.audioPlayer startSession];
    
    self.numberFormatter = [[NSNumberFormatter alloc] init];
    self.numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
}

#pragma mark - CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    switch (central.state) {
        case CBCentralManagerStatePoweredOff:
            NSLog(@"CoreBluetooth BLE hardware is powered off");
            break;
        case CBCentralManagerStatePoweredOn:
            NSLog(@"CoreBluetooth BLE hardware is powered on and ready");
            [self.centralManager scanForPeripheralsWithServices:nil options:nil];
            break;
        case CBCentralManagerStateResetting:
            NSLog(@"CoreBluetooth BLE hardware is resetting");
            break;
        case CBCentralManagerStateUnauthorized:
            NSLog(@"CoreBluetooth BLE state is unauthorized");
            break;
        case CBCentralManagerStateUnknown:
            NSLog(@"CoreBluetooth BLE state is unknown");
            break;
        case CBCentralManagerStateUnsupported:
            NSLog(@"CoreBluetooth BLE hardware is unsupported on this platform");
            break;
        default:
            break;
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    if ([peripheral.name isEqualToString:@"Adafruit Bluefruit LE"]) {
        self.currentPeripheral = peripheral;
        [self.centralManager connectPeripheral:self.currentPeripheral options:nil];
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    NSLog(@"Connection successfully to peripheral: %@", peripheral);
    [self.activityIndicator stopAnimating];
    self.greenLedButton.hidden = NO;
    self.connectingLabel.text = @"Connected!";
    [self.currentPeripheral setDelegate:self];
    [self.currentPeripheral discoverServices:nil];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"Connection failed to peripheral: %@",peripheral);
}

#pragma mark - CBPeripheralDelegate

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    for (CBService *service in peripheral.services) {
        [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:RX_UUID], [CBUUID UUIDWithString:TX_UUID]] forService:service];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    for (CBCharacteristic *characteristic in service.characteristics) {
        CBUUID *uuid = [characteristic UUID];
        if ([uuid  isEqual:[CBUUID UUIDWithString:TX_UUID]]) {
            
            self.transferCharacteristic = characteristic;

        }
        // Listen for receiving messages
        if ([uuid isEqual:[CBUUID UUIDWithString:RX_UUID]]) {
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
        }
    }
}

// Invoked when you retrieve a specified characteristic's value, or when the peripheral device notifies your app that the characteristic's value has changed.
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSString *stringFromData = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
    NSArray *values = [ViewController valuesFromDataString:stringFromData];
    for (int track = 0 ; track < values.count ; track++) {
        NSString *valueString = values[track];
        NSNumber *valueNumber = [self.numberFormatter numberFromString:valueString];
        if (valueNumber.intValue > 350) {
            [self.audioPlayer playTrack:track];
        }
        else {
            [self.audioPlayer pauseTrack:track];
        }
    }
    NSLog(@"Received data: %@ from: %@", stringFromData, characteristic.UUID);
}

+ (NSArray *)valuesFromDataString:(NSString *)dataString {
    NSError* regexError = nil;
    NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:@"(\\d{1,100})" options:NSRegularExpressionCaseInsensitive|NSRegularExpressionDotMatchesLineSeparators error:&regexError];
    if (regexError) {
        NSLog(@"Regex creation failed with error: %@", [regexError description]);
        return nil;
    }
    
    NSArray *matches = [regex matchesInString:dataString options:NSMatchingWithoutAnchoringBounds range:NSMakeRange(0, dataString.length)];
    NSMutableArray *mutableValues = [NSMutableArray array];
    for (NSTextCheckingResult *result in matches) {
        NSString *value = [dataString substringWithRange:result.range];
        [mutableValues addObject:value];
    }
    return mutableValues.copy;
}

#pragma mark - Buttons

- (IBAction)greenButtonPressed:(id)sender {
    if (self.transferCharacteristic) {
        if (!self.greenLedLit) {
            NSData* data = [@"greenon" dataUsingEncoding:NSUTF8StringEncoding];
            [self.currentPeripheral writeValue:data forCharacteristic:self.transferCharacteristic type:CBCharacteristicWriteWithResponse];
            [self.greenLedButton setBackgroundImage:[UIImage imageNamed:@"greenled"] forState:UIControlStateNormal];
                self.greenLedLit = YES;
        } else {
            NSData* data = [@"greenoff" dataUsingEncoding:NSUTF8StringEncoding];
            [self.currentPeripheral writeValue:data forCharacteristic:self.transferCharacteristic type:CBCharacteristicWriteWithResponse];
            [self.greenLedButton setBackgroundImage:[UIImage imageNamed:@"clear"] forState:UIControlStateNormal];
            self.greenLedLit = NO;
        }
    }
}


@end
