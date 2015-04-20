/*
 * TNLibvirtDeviceDiskDriver.j
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

@import "TNLibvirtBase.j";

TNLibvirtDeviceDiskDriverNameTap                    = @"tap";
TNLibvirtDeviceDiskDriverNameTap2                   = @"tap2";
TNLibvirtDeviceDiskDriverNamePhy                    = @"phy";
TNLibvirtDeviceDiskDriverNameFile                   = @"file";
TNLibvirtDeviceDiskDriverNameQemu                   = @"qemu";

TNLibvirtDeviceDiskDriverName                       = [ TNLibvirtDeviceDiskDriverNameTap,
                                                        TNLibvirtDeviceDiskDriverNameTap2,
                                                        TNLibvirtDeviceDiskDriverNamePhy,
                                                        TNLibvirtDeviceDiskDriverNameFile,
                                                        TNLibvirtDeviceDiskDriverNameQemu];

TNLibvirtDeviceDiskDriverTypeAio                    = @"aio";
TNLibvirtDeviceDiskDriverTypeRaw                    = @"raw";
TNLibvirtDeviceDiskDriverTypeCow                    = @"cow";
TNLibvirtDeviceDiskDriverTypeQcow                   = @"qcow";
TNLibvirtDeviceDiskDriverTypeQcow2                  = @"qcow2";
TNLibvirtDeviceDiskDriverTypeVmdk                   = @"vmdk";

TNLibvirtDeviceDiskDriverType                       = [ TNLibvirtDeviceDiskDriverTypeAio,
                                                        TNLibvirtDeviceDiskDriverTypeRaw,
                                                        TNLibvirtDeviceDiskDriverTypeCow,
                                                        TNLibvirtDeviceDiskDriverTypeQcow,
                                                        TNLibvirtDeviceDiskDriverTypeQcow2,
                                                        TNLibvirtDeviceDiskDriverTypeVmdk];


TNLibvirtDeviceDiskDriverCacheDefault               = @"default";
TNLibvirtDeviceDiskDriverCacheNone                  = @"none";
TNLibvirtDeviceDiskDriverCacheWritethrough          = @"writethrough";
TNLibvirtDeviceDiskDriverCacheWriteback             = @"writeback";

TNLibvirtDeviceDiskDriverCaches                     = [ TNLibvirtDeviceDiskDriverCacheDefault,
                                                        TNLibvirtDeviceDiskDriverCacheNone,
                                                        TNLibvirtDeviceDiskDriverCacheWritethrough,
                                                        TNLibvirtDeviceDiskDriverCacheWriteback];

TNLibvirtDeviceDiskDriverIoNative                   = @"native";
TNLibvirtDeviceDiskDriverIoThreads                  = @"threads";
TNLibvirtDeviceDiskDriverIo                         = [ TNLibvirtDeviceDiskDriverIoNative,
                                                        TNLibvirtDeviceDiskDriverIoThreads];

TNLibvirtDeviceDiskDriverDiscardUnmap               = @"unmap";
TNLibvirtDeviceDiskDriverDiscardIgnore              = @"ignore";
TNLibvirtDeviceDiskDriverDiscard                    = [ TNLibvirtDeviceDiskDriverDiscardUnmap,
                                                        TNLibvirtDeviceDiskDriverDiscardIgnore];


/*! @ingroup virtualmachinedefinition
    Model for disk driver
*/
@implementation TNLibvirtDeviceDiskDriver : TNLibvirtBase
{
    CPString    _cache          @accessors(property=cache);
    CPString    _io             @accessors(property=io);
    CPString    _name           @accessors(property=name);
    CPString    _type           @accessors(property=type);
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
            [CPException raise:@"XML not valid" reason:@"The TNXMLNode provided is not a valid disk driver"];

        _cache   = [aNode valueForAttribute:@"cache"] || TNLibvirtDeviceDiskDriverCacheDefault;
        _name    = [aNode valueForAttribute:@"name"];
        _type    = [aNode valueForAttribute:@"type"];
        _io      = [aNode valueForAttribute:@"io"];
        _discard = [aNode valueForAttribute:@"discard"];
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

    if (_cache)
        [node setValue:_cache forAttribute:@"cache"];
    if (_name)
        [node setValue:_name forAttribute:@"name"];
    if (_type)
        [node setValue:_type forAttribute:@"type"];
    if (_io)
        [node setValue:_IO forAttribute:@"io"];
    if (_discard)
        [node setValue:_discard forAttribute:@"discard"];

    return node;
}
@end
