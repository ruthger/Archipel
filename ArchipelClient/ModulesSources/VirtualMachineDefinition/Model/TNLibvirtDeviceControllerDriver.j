/*
 * TNLibvirtDeviceControllerDriver.j
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
@import <StropheCappuccino/TNXMLNode.j>

@import "TNLibvirtBase.j"

/*! @ingroup virtualmachinedefinition
    Model for controller's driver
*/
@implementation TNLibvirtDeviceControllerDriver : TNLibvirtBase
{
    CPString    _queues         @accessors(property=queues);
    CPString    _cmdPerLun      @accessors(property=cmdPerLun);
    CPString    _maxSectors     @accessors(property=maxSectors);
    CPString    _ioeventfd      @accessors(property=ioeventfd);
}


#pragma mark -
#pragma mark Initialization

/*! initialize the object with a given XML node
    @param aNode the node to use
*/
- (id)initWithXMLNode:(TNXMLNode)aNode
{
    if (self = [super initWithXMLNode:aNode])
    {
        if ([aNode name] != @"driver")
            [CPException raise:@"XML not valid" reason:@"The TNXMLNode provided is not a valid controller driver"];

        if ([aNode containsChildrenWithName:@"queues"])
            _queues         = [aNode valueForAttribute:@"queues"];
        if ([aNode containsChildrenWithName:@"cmd_per_lun"])
            _cmdPerLun      = [aNode valueForAttribute:@"cmd_per_lun"];
        if ([aNode containsChildrenWithName:@"max_sectors"])
            _maxSectors     = [aNode valueForAttribute:@"max_sectors"];
        if ([aNode containsChildrenWithName:@"ioeventfd"])
            _ioeventfd      = [aNode valueForAttribute:@"ioeventfd"];
    }

    return self;
}


#pragma mark -
#pragma mark Generation

/*! return a TNXMLNode representing the object
    @return TNXMLNode
*/
- (TNXMLNode)XMLNode
{
    var node = [TNXMLNode nodeWithName:@"driver"];

    if (_queues)
        [node setValue:_queues forAttribute:@"queues"];

    if (_cmdPerLun)
        [node setValue:_cmdPerLun forAttribute:@"cmd_per_lun"];

    if (_maxSectors)
        [node setValue:_maxSectors forAttribute:@"max_sectors"];

    if (_ioeventfd)
        [node setValue:_ioeventfd forAttribute:@"ioeventfd"];

    return node;
}

@end
