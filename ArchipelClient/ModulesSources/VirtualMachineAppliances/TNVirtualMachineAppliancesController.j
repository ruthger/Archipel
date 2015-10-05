/*
 * TNSampleTabModule.j
 *
 * Copyright (C) 2010 Antoine Mercadal <antoine.mercadal@inframonde.eu>
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */


@import <Foundation/Foundation.j>

@import <AppKit/CPButton.j>
@import <AppKit/CPSearchField.j>
@import <AppKit/CPTableView.j>
@import <AppKit/CPTextField.j>
@import <AppKit/CPView.j>
@import <AppKit/CPWindow.j>
@import <AppKit/CPCheckBox.j>
@import <AppKit/CPPopover.j>

@import <TNKit/TNAlert.j>
@import <TNKit/TNTableViewDataSource.j>

@import "../../Model/TNModule.j"
@import "../../Views/TNButtonBar.j"
@import "TNInstalledAppliancesObject.j";

@global CPLocalizedString
@global CPLocalizedStringFromTableInBundle


var TNArchipelTypeVirtualMachineVMCasting           = @"archipel:virtualmachine:vmcasting",
    TNArchipelTypeVirtualMachineVMCastingGet        = @"get",
    TNArchipelTypeVirtualMachineVMCastingAttach     = @"attach",
    TNArchipelTypeVirtualMachineVMCastingDetach     = @"detach",
    TNArchipelTypeVirtualMachineVMCastingPackage    = @"package",
    TNArchipelPushNotificationVMCasting             = @"archipel:push:vmcasting";

var TNModuleControlForAttachAppliance               = @"AttachAppliance",
    TNModuleControlForDetachAppliance               = @"DetachAppliance",
    TNModuleControlForCreateAppliance               = @"CreateAppliance";

/*! @defgroup  virtualmachinepackaging Module VirtualMachine Appliances
    @desc Allow to attach virtual machine from installed appliances
*/

/*! @ingroup virtualmachinepackaging
    main class of the module
*/
@implementation TNVirtualMachineAppliancesController : TNModule
{
    @outlet CPButton                    buttonCreate;
    @outlet TNButtonBar                 buttonBarControl;
    @outlet CPCheckBox                  checkBoxShouldGZIP;
    @outlet CPCheckBox                  checkBoxIncludeISO;
    @outlet CPPopover                   popoverNewAppliances;
    @outlet CPSearchField               fieldFilterAppliance;
    @outlet CPTableView                 tableAppliances;
    @outlet CPTextField                 fieldNewApplianceName;
    @outlet CPView                      viewTableContainer;

    TNTableViewDataSource               _appliancesDatasource;
}


#pragma mark -
#pragma mark Initialization

/*! called at cib awaking
*/
- (void)awakeFromCib
{
    [viewTableContainer setBorderedWithHexColor:@"#F2F2F2"];

    // table appliances
    _appliancesDatasource    = [[TNTableViewDataSource alloc] init];
    [tableAppliances setTarget:self];
    [tableAppliances setDelegate:self];
    [tableAppliances setDoubleAction:@selector(tableDoubleClicked:)];
    [_appliancesDatasource setTable:tableAppliances];
    [_appliancesDatasource setSearchableKeyPaths:[@"name", @"path", @"comment"]]
    [tableAppliances setDataSource:_appliancesDatasource];
    [fieldFilterAppliance setTarget:_appliancesDatasource];
    [fieldFilterAppliance setAction:@selector(filterObjects:)];


    [self addControlsWithIdentifier:TNModuleControlForAttachAppliance
                              title:CPBundleLocalizedString(@"Use the selected appliance", @"Use the selected appliance")
                             target:self
                             action:@selector(attach:)
                              image:CPImageInBundle(@"IconsButtons/lock.png",nil, [CPBundle mainBundle])];

    [self addControlsWithIdentifier:TNModuleControlForDetachAppliance
                              title:CPBundleLocalizedString(@"Detach the selected appliance", @"Detach the selected appliance")
                             target:self
                             action:@selector(detach:)
                              image:CPImageInBundle(@"IconsButtons/unlock.png",nil, [CPBundle mainBundle])];

    [self addControlsWithIdentifier:TNModuleControlForCreateAppliance
                              title:CPBundleLocalizedString(@"Create a new appliance from current virtual machine", @"Create a new appliance from current virtual machine")
                             target:self
                             action:@selector(openNewApplianceWindow:)
                              image:CPImageInBundle(@"IconsButtons/package.png",nil, [CPBundle mainBundle])];

    [buttonBarControl setButtons:[
        [self buttonWithIdentifier:TNModuleControlForAttachAppliance],
        [self buttonWithIdentifier:TNModuleControlForDetachAppliance],
        [self buttonWithIdentifier:TNModuleControlForCreateAppliance]]];
}


#pragma mark -
#pragma mark TNModule overrides

/*! called when module is loaded
*/
- (BOOL)willLoad
{
    if (![super willLoad])
        return NO;

    [[CPNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_didUpdatePresence:)
                                                 name:TNStropheContactPresenceUpdatedNotification
                                               object:_entity];

    [self registerSelector:@selector(_didReceivePush:) forPushNotificationType:TNArchipelPushNotificationVMCasting];

    [tableAppliances setDelegate:nil];
    [tableAppliances setDelegate:self]; // hum....

    return YES;
}

/*! called when module becomes visible
*/
- (BOOL)willShow
{
    if (![super willShow])
        return NO;

    [self getInstalledAppliances];
    [self checkIfRunning];

    return YES;
}

/*! called when module becomes unvisible
*/
- (void)willHide
{
    [popoverNewAppliances close];
    [super willHide];
}

/*! called when user permissions changed
*/
- (void)permissionsChanged
{
    [super permissionsChanged];
    [self tableViewSelectionDidChange:nil];
}

/*! called when the UI needs to be updated according to the permissions
*/
- (void)setUIAccordingToPermissions
{
    [self setControl:[self buttonWithIdentifier:TNModuleControlForCreateAppliance] enabledAccordingToPermission:@"appliance_package"];
    [self setControl:[self buttonWithIdentifier:TNModuleControlForAttachAppliance] enabledAccordingToPermission:@"appliance_attach"];
    [self setControl:[self buttonWithIdentifier:TNModuleControlForDetachAppliance] enabledAccordingToPermission:@"appliance_detach"];

    if ([self currentEntityHasPermission:@"appliance_package"])
        [popoverNewAppliances close];
}

/*! this message is used to flush the UI
*/
- (void)flushUI
{
    [_appliancesDatasource removeAllObjects];
    [tableAppliances reloadData];
}


#pragma mark -
#pragma mark Notification handlers

/*! called if entity changes it presence and call checkIfRunning
    @param aNotification the notification
*/
- (void)_didUpdatePresence:(CPNotification)aNotification
{
    [self checkIfRunning];
}

/*! called when an Archipel push is received
    @param somePushInfo CPDictionary containing the push information
*/
- (BOOL)_didReceivePush:(CPDictionary)somePushInfo
{
    var sender  = [somePushInfo objectForKey:@"owner"],
        type    = [somePushInfo objectForKey:@"type"],
        change  = [somePushInfo objectForKey:@"change"],
        date    = [somePushInfo objectForKey:@"date"];

    switch (change)
    {
        case @"packaging":
            [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:[_entity name]
                                                             message:CPBundleLocalizedString(@"Packaging started.", @"Packaging started.")];
            break;

        case @"packagingerror":
            [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:[_entity name]
                                                             message:CPBundleLocalizedString(@"Unable to create package. Check agent logs", @"Unable to create package. Check agent logs")
                                                                icon:TNGrowlIconError];
            break;

        case @"packaged":
            [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:[_entity name]
                                                             message:CPBundleLocalizedString(@"Packaging successful.", @"Packaging successful.")];
            [self getInstalledAppliances];
            break

        case @"applianceinstalled":
            [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:[_entity name]
                                                             message:CPBundleLocalizedString(@"Appliance is installed.", @"Appliance is installed.")];
            [self getInstalledAppliances];
            break;

        default:
            [self getInstalledAppliances];
    }

    return YES;
}


#pragma mark -
#pragma mark Utilities

/*! Checks if virtualmacine is not running otherwise displays the masking view
*/
- (void)checkIfRunning
{
    if ([_entity XMPPShow] == TNStropheContactStatusBusy)
        [self showMaskView:NO];
    else
        [self showMaskView:YES];
}


#pragma mark -
#pragma mark Actions

/*! Open the new appliance window
    @param sender the sender of the action
*/
- (IBAction)openNewApplianceWindow:(id)aSender
{
    [fieldNewApplianceName setStringValue:[CPString UUID]];
    [checkBoxShouldGZIP setState:CPOnState];
    [checkBoxIncludeISO setState:CPOffState];

    [popoverNewAppliances close];
    [popoverNewAppliances showRelativeToRect:nil ofView:[self buttonWithIdentifier:TNModuleControlForCreateAppliance] preferredEdge:nil]
    [popoverNewAppliances makeFirstResponder:fieldNewApplianceName];
    [popoverNewAppliances setDefaultButton:buttonCreate];
}

/*! close the new appliance window
    @param sender the sender of the action
*/
- (IBAction)closeNewApplianceWindow:(id)aSender
{
    [popoverNewAppliances close];
}

/*! performed when we double click on package from table view.
    it will attach or detach
    @param sender the sender of the action
*/
- (IBAction)tableDoubleClicked:(id)aSender
{
    if ([tableAppliances numberOfSelectedRows] <= 0)
        return;

    var selectedIndex   = [[tableAppliances selectedRowIndexes] firstIndex],
        appliance       = [_appliancesDatasource objectAtIndex:selectedIndex];

    if ([appliance statusString] == TNArchipelApplianceStatusInstalled)
        [self detach];
    else
        [self attach];
}

/*! attach the selected appliance
    @param sender the sender of the action
*/
- (IBAction)attach:(id)aSender
{
    [self requestVisible];
    if (![self isVisible])
        return;

    [self attach];
}

/*! detach the selected appliance
    @param sender the sender of the action
*/
- (IBAction)detach:(id)aSender
{
    [self requestVisible];
    if (![self isVisible])
        return;

    [self detach];
}

/*! package the selected appliance
    @param sender the sender of the action
*/
- (IBAction)package:(id)aSender
{
    [self requestVisible];
    if (![self isVisible])
        return;

    [self package];
}


#pragma mark -
#pragma mark XMPP Controls

/*! ask for installed appliances
*/
- (void)getInstalledAppliances
{
    var stanza = [TNStropheStanza iqWithType:@"get"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeVirtualMachineVMCasting}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeVirtualMachineVMCastingGet}];

    [self setModuleStatus:TNArchipelModuleStatusWaiting];
    [_entity sendStanza:stanza andRegisterSelector:@selector(_didReceiveInstalledAppliances:) ofObject:self];
}

/*! compute the answer containing the appliances
    @param aStanza TNStropheStanza containing the answer
*/
- (BOOL)_didReceiveInstalledAppliances:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
    {
        [self flushUI];

        var appliances = [aStanza childrenWithName:@"appliance"];

        for (var i = 0; i < [appliances count]; i++)
        {
            var appliance       = [appliances objectAtIndex:i],
                name            = [appliance valueForAttribute:@"name"],
                comment         = [appliance valueForAttribute:@"description"],
                path            = [appliance valueForAttribute:@"path"],
                uuid            = [appliance valueForAttribute:@"uuid"],
                status          = [appliance valueForAttribute:@"status"],
                newAppliance    = [TNInstalledAppliance InstalledApplianceWithName:name UUID:uuid path:path comment:comment status:status];

            [_appliancesDatasource addObject:newAppliance];
        }
        [tableAppliances reloadData];
        [self setModuleStatus:TNArchipelModuleStatusReady];
    }
    else
    {
        [self setModuleStatus:TNArchipelModuleStatusError];
        [self handleIqErrorFromStanza:aStanza];
    }

    return NO;
}

/*! attach the selected appliance. but before ask user confirmation
*/
- (void)attach
{
    if (([tableAppliances numberOfRows]) && ([tableAppliances numberOfSelectedRows] <= 0))
    {
         [TNAlert showAlertWithMessage:CPBundleLocalizedString(@"Error", @"Error")
                           informative:CPBundleLocalizedString(@"You must select an appliance", @"You must select an appliance")];
         return;
    }

    var alert = [TNAlert alertWithMessage:CPBundleLocalizedString(@"Attach appliance", @"Attach appliance")
                                informative:CPBundleLocalizedString(@"Are you sure you want to attach this appliance? This will reset all your virtual machine.", @"Are you sure you want to attach this appliance? This will reset all your virtual machine.")
                                 target:self
                                 actions:[[CPBundleLocalizedString(@"Attach", @"Attach"), @selector(performAttach:)], [CPBundleLocalizedString(@"Cancel", @"Cancel"), nil]]];
    [alert runModal];
}

/*! attach the selected appliance
*/
- (void)performAttach:(id)someUserInfo
{
    var selectedIndex   = [[tableAppliances selectedRowIndexes] firstIndex],
        appliance       = [_appliancesDatasource objectAtIndex:selectedIndex],
        stanza          = [TNStropheStanza iqWithType:@"set"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeVirtualMachineVMCasting}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeVirtualMachineVMCastingAttach,
        "uuid": [appliance UUID]}];

    if ([self currentEntityHasPermission:@"appliance_attach"])
        [[self buttonWithIdentifier:TNModuleControlForAttachAppliance] setEnabled:NO];

    [_entity sendStanza:stanza andRegisterSelector:@selector(_didAttach:) ofObject:self];
}

/*! compute the attachement results
    @param aStanza TNStropheStanza containing the answer
*/
- (BOOL)_didAttach:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
    {
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:[_entity name]
                                                         message:CPBundleLocalizedString(@"Instanciation has started", @"Instanciation has started")];
    }
    else
    {
        [self handleIqErrorFromStanza:aStanza];
    }

    return NO;
}

/*! detach the selected appliance. but before ask user confirmation
*/
- (void)detach
{
    if (([tableAppliances numberOfRows]) && ([tableAppliances numberOfSelectedRows] <= 0))
    {
         [TNAlert showAlertWithMessage:CPBundleLocalizedString(@"Error", @"Error")
                         informative:CPBundleLocalizedString(@"You must select an appliance", @"You must select an appliance")];
         return;
    }

    var alert = [TNAlert alertWithMessage:CPBundleLocalizedString(@"Detach from appliance", @"Detach from appliance")
                                informative:CPBundleLocalizedString(@"Are you sure you want to detach virtual machine from this appliance?", @"Are you sure you want to detach virtual machine from this appliance?")
                                 target:self
                                 actions:[[CPBundleLocalizedString(@"Detach", @"Detach"), @selector(performDetach:)], [CPBundleLocalizedString(@"Cancel", @"Cancel"), nil]]];
    [alert runModal];
}

/*! detach the selected appliance
*/
- (void)performDetach:(id)someUserInfo
{
    var selectedIndex   = [[tableAppliances selectedRowIndexes] firstIndex],
        appliance       = [_appliancesDatasource objectAtIndex:selectedIndex],
        stanza          = [TNStropheStanza iqWithType:@"set"];

    if ([appliance statusString] != TNArchipelApplianceStatusInstalled)
        return;


    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeVirtualMachineVMCasting}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeVirtualMachineVMCastingDetach}];

    if ([self currentEntityHasPermission:@"appliance_attach"])
        [[self buttonWithIdentifier:TNModuleControlForDetachAppliance] setEnabled:NO];

    [_entity sendStanza:stanza andRegisterSelector:@selector(_didDetach:) ofObject:self];
}

/*! compute the detachment results
    @param aStanza TNStropheStanza containing the answer
*/
- (BOOL)_didDetach:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
    {
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:[_entity name]
                                                         message:CPBundleLocalizedString(@"Appliance has been detached", @"Appliance has been detached")];

        [self setControl:[self buttonWithIdentifier:TNModuleControlForAttachAppliance] enabledAccordingToPermission:@"appliance_attach"];
    }
    else
    {
        [self handleIqErrorFromStanza:aStanza];
    }

    return NO;
}

/*! package the selected appliance
*/
- (void)package
{
    if ([_entity XMPPShow] != TNStropheContactStatusBusy)
    {
         [TNAlert showAlertWithMessage:CPBundleLocalizedString(@"Error", @"Error")
                         informative:CPBundleLocalizedString(@"Virtual machine must not be running to package it.", @"Virtual machine must not be running to package it.")];
         return;
    }

    var stanza      = [TNStropheStanza iqWithType:@"get"],
        name        = [fieldNewApplianceName stringValue],
        shouldGZIP  = [checkBoxShouldGZIP state] == CPOnState ? "True" : "False",
        includeISO  = [checkBoxIncludeISO state] == CPOnState ? "True" : "False";

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeVirtualMachineVMCasting}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action":      TNArchipelTypeVirtualMachineVMCastingPackage,
        "name":        name,
        "gzip":        shouldGZIP,
        "include_iso": includeISO}];

    [_entity sendStanza:stanza andRegisterSelector:@selector(_didPackageAppliance:) ofObject:self];

    [popoverNewAppliances close];
}

/*! compute the packaging results
    @param aStanza TNStropheStanza containing the answer
*/
- (BOOL)_didPackageAppliance:(TNStropheStanza)aStanza
{
    if ([aStanza type] != @"result")
        [self handleIqErrorFromStanza:aStanza];

    return NO;
}


#pragma mark -
#pragma mark Delegates

- (void)tableViewSelectionDidChange:(CPTableView)aTableView
{
    [[self buttonWithIdentifier:TNModuleControlForAttachAppliance] setEnabled:NO];
    [[self buttonWithIdentifier:TNModuleControlForDetachAppliance] setEnabled:NO];

    if ([tableAppliances numberOfSelectedRows] <= 0)
        return;

    var selectedIndex   = [[tableAppliances selectedRowIndexes] firstIndex],
        appliance       = [_appliancesDatasource objectAtIndex:selectedIndex];

    if ([appliance statusString] == TNArchipelApplianceStatusInstalled)
        [self setControl:[self buttonWithIdentifier:TNModuleControlForDetachAppliance] enabledAccordingToPermission:@"appliance_detach"];
    else
        [self setControl:[self buttonWithIdentifier:TNModuleControlForAttachAppliance] enabledAccordingToPermission:@"appliance_attach"];
}

/*! Delegate of CPTableView - This will be called when context menu is triggered with right click
*/
- (CPMenu)tableView:(CPTableView)aTableView menuForTableColumn:(CPTableColumn)aColumn row:(int)aRow
{

    if ([aTableView selectedRow] != aRow)
        if (aRow >= 0)
            [aTableView selectRowIndexes:[CPIndexSet indexSetWithIndex:aRow] byExtendingSelection:NO];
        else
            [aTableView deselectAll];

    if ([aTableView numberOfSelectedRows] > 1)
        return;

    [_contextualMenu removeAllItems];

    if (([aTableView numberOfSelectedRows] == 0) && (aTableView == tableAppliances))
    {
        [_contextualMenu addItem:[self menuItemWithIdentifier:TNModuleControlForCreateAppliance]];
        return _contextualMenu;
    }

    var selectedIndex   = [[tableAppliances selectedRowIndexes] firstIndex],
        appliance       = [_appliancesDatasource objectAtIndex:selectedIndex];

    if ([appliance statusString] == TNArchipelApplianceStatusInstalled)
        [_contextualMenu addItem:[self menuItemWithIdentifier:TNModuleControlForDetachAppliance]];
    else
        [_contextualMenu addItem:[self menuItemWithIdentifier:TNModuleControlForAttachAppliance]];

    return _contextualMenu;
}

@end



// add this code to make the CPLocalizedString looking at
// the current bundle.
function CPBundleLocalizedString(key, comment)
{
    return CPLocalizedStringFromTableInBundle(key, nil, [CPBundle bundleForClass:TNVirtualMachineAppliancesController], comment);
}
