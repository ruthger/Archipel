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
@import "TNLibvirDomainFeaturesAPIC.j"
@import "TNLibvirDomainFeaturesHyperv.j"

TNLibvirtDomainFeaturesPAE      = @"pae";
TNLibvirtDomainFeaturesACPI     = @"acpi";
TNLibvirtDomainFeaturesHAP      = @"hap";
TNLibvirtDomainFeaturesAPIC     = @"apic";
TNLibvirtDomainFeaturesHyperv   = @"apic";

/*! @ingroup virtualmachinedefinition
    Model for features
*/
@implementation TNLibvirtDomainFeatures : TNLibvirtBase
{
    BOOL                          _ACPI   @accessors(getter=isACPI, setter=setACPI:);
    BOOL                          _HAP    @accessors(getter=isHAP, setter=setHAP:);
    BOOL                          _PAE    @accessors(getter=isPAE, setter=setPAE:);
    TNLibvirtDomainFeaturesAPIC   _APIC   @accessors(property=APIC);
    TNLibvirtDomainFeaturesHyperv _hyperv @accessors(property=hyperv);
}


#pragma mark -
#pragma mark Initialization

/*! initialize the Disk
*/
- (id)init
{
    if (self = [super init])
    {
        _APIC       = [[TNLibvirtDomainFeaturesAPIC alloc] init];
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
	
        _ACPI   = [aNode firstChildWithName:@"acpi"] ? YES : NO;
        _HAP    = [aNode firstChildWithName:@"hap"] ? YES : NO;
        _PAE    = [aNode firstChildWithName:@"pae"] ? YES : NO;

        _APIC   = [[TNLibvirtDomainFeaturesAPIC alloc] initWithXMLNode:[aNode firstChildWithName:@"apic"]];
        _hyperv = [[TNLibvirtDomainFeaturesHyperv alloc] initWithXMLNode:[aNode firstChildWithName:@"hyperv"]];
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
    if (_PAE)
    {
        [node addChildWithName:@"pae"];
        [node up];
    }
    if (_ACPI)
    {
        [node addChildWithName:@"acpi"];
        [node up];
    }
    if (_HAP)
    {
        [node addChildWithName:@"hap"];
        [node up];
    }
    if (_APIC)
    {
        [node addChildWithName:@"apic"];
        [node up];
    }
    if (_hyperv)
    {
        [node addChildWithName:@"hyperv"];
        [node up];
    }

    return node;
}

@end
