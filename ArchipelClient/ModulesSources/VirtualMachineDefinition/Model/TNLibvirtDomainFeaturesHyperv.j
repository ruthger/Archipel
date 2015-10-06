/*
 * TNLibvirtDomainFeatures.j
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
@import "TNLibvirtDomainFeaturesHypervRelaxed.j"
@import "TNLibvirtDomainFeaturesHypervVapic.j"
@import "TNLibvirtDomainFeaturesHypervSpinlocks.j"


/*! @ingroup virtualmachinedefinition
    Model for features
*/
@implementation TNLibvirtDomainFeatures : TNLibvirtBase
{
    TNLibvirtDomainFeaturesHypervRelaxed   _relaxed    @accessors(property=relaxed);
    TNLibvirtDomainFeaturesHypervVApic     _vapic      @accessors(property=vapic);
    TNLibvirtDomainFeaturesHypervSpinlocks _spinlocks  @accessors(property=spinlocks);
}


#pragma mark -
#pragma mark Initialization

/*! initialize the HyperV features
*/
- (id)init
{
    if (self = [super init])
    {
        _relaxed    = [[TNLibvirtDomainFeaturesHypervRelaxed alloc] init];
        _vapic      = [[TNLibvirtDomainFeaturesHypervVApic alloc] init];
        _spinlocks  = [[TNLibvirtDomainFeaturesHypervSpinlocks alloc] init];
    }

    return self;
}

/*! initialize the object with a given XML node
    @param aNode the node to use
*/
- (id)initWithXMLNode:(TNXMLNode)aNode
{
    if (self = [super initWithXMLNode:aNode])
    {
        if ([aNode name] != @"features")
            [CPException raise:@"XML not valid" reason:@"The TNXMLNode provided is not a valid features"];

        _relaxed   = [[TNLibvirtDomainFeaturesHypervRelaxed alloc]   initWithXMLNode:[aNode firstChildWithName:@"relaxed"]];
        _vapic     = [[TNLibvirtDomainFeaturesHypervVapic alloc]     initWithXMLNode:[aNode firstChildWithName:@"vapic"]];
        _spinlocks = [[TNLibvirtDomainFeaturesHypervSpinlocks alloc] initWithXMLNode:[aNode firstChildWithName:@"spinlocks"]];
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
    var node = [TNXMLNode nodeWithName:@"hyperv"];

    if (_relaxed)
    {
        [node addChildWithName:@"relaxed"];
        [node up];
    }
    if (_vapic)
    {
        [node addChildWithName:@"vapic"];
        [node up];
    }
    if (_spinlocks)
    {
        [node addChildWithName:@"spinlocks"];
        [node up];
    }

    return node;
}

@end
