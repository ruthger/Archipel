# -*- coding: utf-8 -*-
#
# runutils.py
#
# Copyright (C) 2010 Antoine Mercadal <antoine.mercadal@inframonde.eu>
# This file is part of ArchipelProject
# http://archipelproject.org
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


"""
this module contains functions common to runarchipel and runcentralagent
"""

import commands
import os
import socket
import subprocess
import sys

from archipelcore.scriptutils import error, msg, success
from archipelcore.utils import init_conf

## Error codes
ARCHIPEL_INIT_SUCCESS = 0
ARCHIPEL_INIT_ERROR_NO_CONFIG = 1
ARCHIPEL_INIT_ERROR_STATELESS_MODE = 7

def format_version(info):
    """
    Format the version info
    @type info: list
    @param info: plugin informations
    """
    if len(info) == 2:
        print " - %s: %s" % (info[0], info[1])
    else:
        print " - %s: %s" % (info[0], info[1])
        for p in info[2]:
            print "     + %s" % p["identifier"]

def versions():
    """
    Display all the versions
    """
    import pkg_resources
    """print versions of all installed modules"""
    print "* Archipel Agent version :"
    format_version(("archipelagent", pkg_resources.get_distribution("archipel-agent").version))
    print "\n* Installed plugins versions :"
    for version_method in pkg_resources.iter_entry_points(group="archipel.plugin", name="version"):
        try:
            method = version_method.load()
            format_version(method())
        except Exception as ex:
            error("unable to get the version of one plugin: %s" % ex, exit=False)
    sys.exit(ARCHIPEL_INIT_SUCCESS)

def stateless_read_kernel_parameters(path="/proc/cmdline"):
    """
    Read the kernel parameters
    @type path: string
    @param path: the path to the file containing the kernel params (Default: /proc/cmdline)
    @rtype: dict
    @return: dictionnary containing the archipel informations
    """
    f = open(path, "r")
    cmdline = f.read()
    f.close()
    tokens = cmdline.replace(" ARCHIPEL_", "\nARCHIPEL_").split("\n")
    ret = {}
    for token in tokens:
        if token.startswith("ARCHIPEL_"):
            ret[token.split("=", 1)[0]] = token.split("=", 1)[1].split(" ")[0].strip()

    # Check we have all the needed kernel parameters
    if not "ARCHIPEL_MOUNT_ADDRESS" in ret:
        raise Exception("You need to set the kernel parameter ARCHIPEL_MOUNT_ADDRESS")

    # Set default value if tokens missing

    ## MOUNT
    if not "ARCHIPEL_MOUNT_TYPE" in ret:
        ret["ARCHIPEL_MOUNT_TYPE"] = "cifs"

    if not "ARCHIPEL_MOUNT_MOUNTPOINT" in ret:
        ret["ARCHIPEL_MOUNT_MOUNTPOINT"] = "/stateless"

    if not "ARCHIPEL_MOUNT_OPTIONS" in ret:
        ret["ARCHIPEL_MOUNT_OPTIONS"] = None

    ## STATELESS FOLDERS
    if not "ARCHIPEL_STATELESS_PATH" in ret:
        ret["ARCHIPEL_STATELESS_PATH"] = os.path.join(ret["ARCHIPEL_MOUNT_MOUNTPOINT"])

    if not "ARCHIPEL_STATELESS_CONFIG_PATH" in ret:
        ret["ARCHIPEL_STATELESS_CONFIG_PATH"] = os.path.join(ret["ARCHIPEL_STATELESS_PATH"], "config")

    if not "ARCHIPEL_STATELESS_LIB_PATH" in ret:
        ret["ARCHIPEL_STATELESS_LIB_PATH"] = os.path.join(ret["ARCHIPEL_STATELESS_PATH"], "lib", socket.gethostname())

    if not "ARCHIPEL_STATELESS_QEMU_PATH" in ret:
        ret["ARCHIPEL_STATELESS_QEMU_PATH"] = os.path.join(ret["ARCHIPEL_STATELESS_PATH"], "qemu", socket.gethostname())

    if not "ARCHIPEL_POST_SCRIPT" in ret:
        ret["ARCHIPEL_POST_SCRIPT"] = os.path.join(ret["ARCHIPEL_STATELESS_PATH"], "scripts", "archipel-mount-post")

    if not "ARCHIPEL_STATELESS_CONFIG_PATH_GENERAL" in ret:
        ret["ARCHIPEL_STATELESS_CONFIG_PATH_GENERAL"] = os.path.join(ret["ARCHIPEL_STATELESS_CONFIG_PATH"], "archipel.conf")

    if not "ARCHIPEL_STATELESS_CONFIG_PATH_LOCAL" in ret:
        ret["ARCHIPEL_STATELESS_CONFIG_PATH_LOCAL"] = None

    ## STATELESS SELINUX
    if not "ARCHIPEL_SELINUX_MODE" in ret:
        ret["ARCHIPEL_SELINUX_MODE"] = "Permissive"

    return ret

def initialize_config(paths, cmdline_path="/proc/cmdline", prepare_only=False):
    """
    Initialize the ConfigParser object
    @type paths: list
    @param paths: list of the path of the config files
    @type cmdline_path: string
    @param cmdline_path: the path of kernel param file
    @type prepare_only: Boolean
    @param prepare_only: if True, we will exit after preparing the config.
    @rtype: ConfigParser
    @return: ready to use config object
    """
    # Read the local config file(s)
    try:
        config = init_conf(paths)
    except Exception as ex:
        error("Unable to read local configuration file(s) %s : %s" % (str(paths), str(ex)), code=ARCHIPEL_INIT_ERROR_NO_CONFIG)

    # If we are in a stateless mode, read the stateless node configuration from the kernel parameters
    if config.has_option("GLOBAL", "stateless_node") and config.getboolean("GLOBAL", "stateless_node"):
        try:
            msg("Archipel is configured to start in stateless mode")
            # Get Kernel parameters
            stateless_mode_parameters = stateless_read_kernel_parameters(cmdline_path)

            p_mount_type = stateless_mode_parameters["ARCHIPEL_MOUNT_TYPE"]
            p_mount_address = stateless_mode_parameters["ARCHIPEL_MOUNT_ADDRESS"]
            p_mount_options = stateless_mode_parameters["ARCHIPEL_MOUNT_OPTIONS"]
            p_mount_mountpoint = stateless_mode_parameters["ARCHIPEL_MOUNT_MOUNTPOINT"]
            p_stateless_path = stateless_mode_parameters["ARCHIPEL_STATELESS_PATH"]
            p_stateless_lib_path = stateless_mode_parameters["ARCHIPEL_STATELESS_LIB_PATH"]
            p_stateless_qemu_path = stateless_mode_parameters["ARCHIPEL_STATELESS_QEMU_PATH"]
            p_stateless_config_path = stateless_mode_parameters["ARCHIPEL_STATELESS_CONFIG_PATH"]
            p_stateless_config_path_general = stateless_mode_parameters["ARCHIPEL_STATELESS_CONFIG_PATH_GENERAL"]
            p_stateless_config_path_local = stateless_mode_parameters["ARCHIPEL_STATELESS_CONFIG_PATH_LOCAL"]
            p_selinux_enforce = stateless_mode_parameters["ARCHIPEL_SELINUX_MODE"]
            p_post_script = stateless_mode_parameters["ARCHIPEL_POST_SCRIPT"]

            # selinux
            msg("Setting selinux in mode %s" % p_selinux_enforce)
            os.system("if test -x `which setenforce`; then setenforce %s; fi" % p_selinux_enforce)

            # Print informations
            msg("Information from /proc/cmdline read:")
            for k, v in stateless_mode_parameters.items():
                msg(" - %s: %s" % (k, v))

            # get current state
            current_mounts = file.read(open("/proc/mounts"))

            # Mount remote filestem
            was_not_stateless_mounted = stateless_mount_storage(current_mounts, p_mount_type, p_mount_address, p_mount_options, p_mount_mountpoint)

            # Create remote folders if needed
            paths = [p_stateless_path, p_stateless_lib_path, p_stateless_qemu_path, p_stateless_config_path]
            for path in paths:
                if not os.path.exists(path):
                    msg("Creating solid state path %s" % path)
                    os.makedirs(path)

            # Mount --bind the /etc/libvirt/qemu to the solid state path
            if was_not_stateless_mounted and "/etc/libvirt/qemu" in current_mounts:
                msg("Umounting /etc/libvirt/qemu")
                subprocess.check_call(["umount", "/etc/libvirt/qemu"])

            if not "/etc/libvirt/qemu" in current_mounts or was_not_stateless_mounted:
                msg("Mounting /etc/libvirt/qemu on %s" % p_stateless_qemu_path)
                subprocess.check_call(["mount", "--bind", p_stateless_qemu_path, "/etc/libvirt/qemu"])
                # We reload the libvirt
                try:
                    if os.path.exists("/bin/systemctl") or os.path.exists("/sbin/systemctl"):
                        subprocess.check_call(["systemctl", "reload", "libvirtd.service"])
                        msg("Libvirt restarted using systemctl")
                    elif os.path.exists("/sbin/service"):
                        subprocess.check_call(["service", "libvirtd", "restart"])
                        msg("Libvirt restarted using service")
                    elif os.path.exists("/etc/init.d/libvirtd"):
                        subprocess.check_call(["/etc/init.d/libvirtd", "restart"])
                        msg("Libvirt restarted using /etc/init.d/libvirtd")
                except:
                    msg("Libvirtd: Not any service file found. Restarted libvirtd like a boss")
                    os.system("killall libvirtd")
                    os.system("libvirtd --daemon")
            else:
                msg("/etc/libvirt/qemu is already mounted on %s. Ignored" % p_stateless_qemu_path)

            # We start the post script if any
            if p_post_script and os.path.exists(p_post_script):
                msg("Running post mount script from %s" % p_post_script)
                subprocess.check_call("%s %s %s" % (p_post_script, socket.gethostname(), " ".join(stateless_mode_parameters)), shell=True)
                msg("Post mount script sucessfully ran")

            # We set the hostname here because the post mount script may have changed it.
            if not p_stateless_config_path_local:
                p_stateless_config_path_local = os.path.join(p_stateless_config_path, "archipel.%s.conf" % socket.gethostname())

            # Reinitialize the configuration according to the kernel parameters about remote config
            msg("Re-read the configuration files %s" % (str([p_stateless_config_path_general, p_stateless_config_path_local])))
            config_files = [p_stateless_config_path_general]
            if os.path.exists(p_stateless_config_path_local):
                msg("Found local config file at %s" % p_stateless_config_path_local)
                config_files.append(p_stateless_config_path_local)
            else:
                msg("Local config file at %s doesn't exist. ignoring it." % p_stateless_config_path_local)
            config = init_conf(config_files)
            msg("Configuration reloaded")

            if prepare_only:
                success("Prepare only mode. exiting")
                sys.exit(ARCHIPEL_INIT_SUCCESS)
            success("Stateless configuration ready")

        except Exception as ex:
            error("Stateless node initialization error: %s" % str(ex), code=ARCHIPEL_INIT_ERROR_STATELESS_MODE)
    return config


def stateless_mount_storage(current_mounts, mount_type, mount_address, mount_options=None, mount_point="/stateless"):
    """
    Mount the remote file system.
    @type mount_type: string
    @param mount_type: the mount type (nfs or cifs)
    @type mount_address: string
    @param mount_address: remote fs URL (i.e. //example.com/share)
    @type mount_options: string
    @param mount_options: the options (i.e. "username=user,password=secret")
    @type mount_point: string
    @param mount_point: mount path (Default: "/stateless")
    """
    if "%s %s " % (mount_address, mount_point) in current_mounts:
        msg("Remote filesystem is already mounted. Ignored")
        return False
    msg("Mouting remote file system from %s (type: %s) to %s" % (mount_address, mount_type, mount_point))
    if not mount_options:
        subprocess.check_call(["mount", "-t", mount_type, mount_address, mount_point])
    else:
        subprocess.check_call(["mount", "-t", mount_type, "-o", mount_options, mount_address, mount_point])
    msg("Remote filesystem sucessfull mounted")
    return True

