# WARNING
# This file is maintained in git-deploy.spec and copied to packages.git by the maintenance tools!
#
# Do not update this file manaully in packages.git

%define booking_repo base

Name:           git-deploy
Version:        1.0
Release:        1
Summary:        Booking.com git-deploy
Group:          Development/Libraries
License:        proprietary
Source:         git-deploy-%{version}-%{release}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildArch:      noarch

%description
This is the booking.com git-deploy repo in RPM form

%prep
%setup -c -b 0

%build

%clean
rm -rf %{buildroot}

%install
mkdir -p %{buildroot}/usr/local/git_tree

# Copy the files into place
cp -a git-deploy %{buildroot}/usr/local/git_tree

# Remove traces o' git
rm -fr %{buildroot}/usr/local/git_tree/git-deploy/.git*

# Symlink
mkdir -p %{buildroot}/usr/local/bin
ln -s /usr/local/git_tree/git-deploy/git-deploy %{buildroot}/usr/local/bin/git-deploy

# And create filelists
find %{buildroot} | sed -e 's!%{buildroot}!!' > git-deploy-filelist

%files -f git-deploy-filelist
%defattr(-,root,root,-)

%changelog
* Tue Apr 17 2012 menno.blom@booking.com
- initial version
