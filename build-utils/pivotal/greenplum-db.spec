## ======================================================================
## RPM spec file for HAWQ
##
##  o Currently, expects the greenplum-db-*.tar.gz file to be present
##    in source working directory root.
## ======================================================================

# disable stripping of debug symbols
%global _enable_debug_package 0
%global debug_package %{nil}
%global __os_install_post /usr/lib/rpm/brp-compress %{nil}

%define name            hawq
%define gpdbname        greenplum-db
%define arch            x86_64

%{!?version:%define version %{greenplum_db_ver}}
%{!?release:%define release %{bld_number}}
%{!?MPP_ARCH:%define MPP_ARCH %{MPP_ARCH}}

%if "%{version}" == "dev"
    %{!?gptarball:%define gptarball %{gpdbname}-%{version}-%{MPP_ARCH}.tar.gz}
%else
    %{!?gptarball:%define gptarball %{gpdbname}-%{version}-build-%{release}-%{MPP_ARCH}.tar.gz}
%endif

%define installdir      /usr/local/%{name}-%{version}
%define symlink         /usr/local/%{name}

## ======================================================================

Summary:        HAWQ, the power behind Pivotal Advanced Database Services (ADS)
Name:           %{name}
Version:        %{version}
Release:        %{release}
License:        Copyright (c) 2014-2015 Pivotal Software, Inc. All Rights reserved.
Vendor:         Pivotal
Group:          Applications/Databases
URL:            http://pivotal.io/big-data/pivotal-hawq
BuildArch:      %{arch}
# This prevents rpmbuild from generating automatic dependecies on
# libraries and binaries. Some of these dependencies cause problems
# while installing the generated RPMS. However, we tested the rpm
# generated after turning AutoReq off and it seemed to work fine.
# Disabled "automatic providing" mechanism.  As we ship syhstem files
# with the same names, this can cause conflicts.
AutoReqProv:    no

BuildRoot:      %{_topdir}/temp
Prefix:         /usr/local
Requires:       ed

## ======================================================================

%description
Pivotal Advanced Database Services (ADS) powered by HAWQ, extends
Pivotal HD Enterprise, adding rich, proven parallel SQL processing
facilities. These render Hadoop queries faster than any Hadoop-based
query interface on the market today, enhancing productivity.

## ======================================================================

%prep
# As the source tarball for this RPM is created during the %%prep phase, we cannot assign the source as SOURCE0: <tar.gz file path>
# To get around this issue, using the command below to manually copy the tar.gz file into the SOURCES directory
cp ../../%{gptarball} %_sourcedir/.

## ======================================================================

%build

## ======================================================================

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT%{installdir}
tar zxf %{_sourcedir}/%{gptarball} -C $RPM_BUILD_ROOT%{installdir}
(cd $RPM_BUILD_ROOT%{installdir}/..; ln -s %{name}-%{version} %{name})

#disable stripping of debug symbols
export DONT_STRIP=1

## ======================================================================

%clean
rm -rf $RPM_BUILD_ROOT

## ======================================================================

%files
%defattr(-, gpadmin, gpadmin, -)
%{installdir}
%{symlink}

## ======================================================================

%post
INSTDIR=$RPM_INSTALL_PREFIX0/%{name}-%{version}
# Update GPHOME in greenplum_path.sh
sed "s|^GPHOME=.*|GPHOME=${INSTDIR}|g" -i ${INSTDIR}/greenplum_path.sh

## ======================================================================
