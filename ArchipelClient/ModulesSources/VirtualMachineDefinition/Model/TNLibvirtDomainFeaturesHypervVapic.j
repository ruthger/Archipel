/*
 * TNLibvirtDomainFeaturesHypervVapic.j
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

TNLibvirtDomainFeaturesHypervVapicState = @"state";


/*! @ingroup virtualmachinedefinition
    Model for features
*/
@implementation TNLibvirtDomainFeatures : TNLibvirtBase
{
    CPString _state   @accessors(property=state);
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
        if ([aNode name] != @"features")
            [CPException raise:@"XML not valid" reason:@"The TNXMLNode provided is not a valid features"];

        _state    = [aNode valueForAttribute:@"state"];
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
    var attributes = ();

    if (_state)
    {
        attributes.state = _state;
    }

    var node = [TNXMLNode nodeWithName:@"vapic" andAttributes:attributes];

    return node;
}

@end
