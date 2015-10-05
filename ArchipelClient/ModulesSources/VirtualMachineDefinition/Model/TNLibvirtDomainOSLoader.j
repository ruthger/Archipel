/*
 * TNLibvirtDomainOSLoader.j
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

TNLibvirtDomainOSLoaderTypePFlash = @"pflash";
TNLibvirtDomainOSLoaderTypeRom    = @"rom";
TNLibvirtDomainOSLoaderType             = [ TNLibvirtDomainOSLoaderTypePFlash,
                                            TNLibvirtDomainOSLoaderTypeRom ];

@import "TNLibvirtBase.j";


/*! @ingroup virtualmachinedefinition
    Model for OS Type
*/
@implementation TNLibvirtDomainOSLoader : TNLibvirtBase
{
    BOOL                        _readonly       @accessors(getter=isReadonly, setter=setReadonly:);
    TNLibvirtDomainLoaderType   _type           @accessors(property=type);
}


#pragma mark -
#pragma mark Initialization

/*! initialize the object with a given XML node
    @param aNode the node to use
*/
- (id)initWithXMLNode:(TNXMLNode)aNode domainLoader:(CPString)aDomainLoader
{
    if (self = [super initWithXMLNode:aNode])
    {
        if ([aNode name] != @"loader")
            [CPException raise:@"XML not valid" reason:@"The TNXMLNode provided is not a valid os loader"];

        _readonly           = ([[aNode firstChildWithName:@"readonly"] valueForAttribute:@"enable"] == @"yes") ? YES : NO;
        _type               = [aNode valueForAttribute:@"type"];
        _loader             = [aNode text];

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
    var node = [TNXMLNode nodeWithName:@"loader"];

    if (_readonly)
        [node setValue:_readonly forAttribute:@"readonly"];

    if (_type)
        [node setValue:_type forAttribute:@"type"];

    [node addTextNode:_loader];

    return node;
}

@end
