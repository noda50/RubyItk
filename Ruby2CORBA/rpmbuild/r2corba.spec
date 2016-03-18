# Set the version number here.
%define R2CORBAVER  0.9.3

%{!?skip_make:%define skip_make 0}
%{!?make_nosrc:%define make_nosrc 0}
%{!?is_major_ver:%define is_major_ver 0}

Summary:      R2CORBA
Name:         ruby-r2corba
Version:      %{R2CORBAVER}
Release:      1%{?OPTTAG}%{?dist}
Group:        Development/Libraries/Ruby
URL:          http://www.theaceorb.nl
License:      DOC License
Source0:      http://download.theaceorb.nl/Ruby2CORBA-%{R2CORBAVER}.tar.bz2
BuildRoot:    %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)

%if !0%{?suse_version}
Requires(post):   /sbin/install-info
Requires(preun):  /sbin/install-info
Requires(postun): /sbin/ldconfig
%else
PreReq:         %install_info_prereq %insserv_prereq  %fillup_prereq
PreReq:         pwdutils
%endif

%if 0%{?mandriva_version}
BuildRequires:  sendmail
%endif

BuildRequires:  gcc-c++
BuildRequires:  libstdc++-devel
BuildRequires:  ruby
BuildRequires:  tao-devel
BuildRequires:  ace-devel
BuildRequires:  perl
BuildRequires:  mpc
BuildRequires:  ruby-devel
Requires:       tao
Requires:       ace
Requires:       ruby(abi) = 1.8
Provides:       ruby(r2corba) = %{R2CORBAVER}

%description
R2CORBA is a product currently which makes it possible to implement
CORBA clients and servers using the Ruby programming language.

%package devel
Summary:      R2CORBA - development files
Group:        Development/Libraries/Ruby
Requires:     r2corba

%description devel
R2CORBA development files.
R2CORBA is a product currently which makes it possible to implement
CORBA clients and servers using the Ruby programming language.

# ================================================================
# prep
# ================================================================

%prep
echo %distribution
%setup -q -n Ruby2CORBA

# ================================================================
# build
# ================================================================

%build

(ruby setup.rb config --without-tao)
%if ! %skip_make
(ruby setup.rb setup)
%endif
#(ruby setup.rb test)

# ================================================================
# install
# ================================================================

# For major releases the package version will be the shortened version
# tuple and the shared-object version needs a placeholder '.0'
%if %is_major_ver
%define R2CORBAVERSO %{R2CORBAVER}.0
%else
%define R2CORBAVERSO %{R2CORBAVER}
%endif

%install

rm -rf %{buildroot}

# make a new build root dir
mkdir %{buildroot}

# ---------------- Runtime Components ----------------


# ---------------- Development Components ----------------

# INSTHDR="cp --preserve=timestamps"
INSTHDR="install -m 0644 -p"

# install headers
ruby setup.rb install --prefix=%{buildroot}

%{!?ruby_sitelib: %define ruby_sitelib %(ruby -rrbconfig -e 'puts Config::CONFIG["sitelibdir"] ')}
%{!?ruby_sitearch: %define ruby_sitearch %(ruby -rrbconfig -e 'puts Config::CONFIG["sitearchdir"] ')}

# ================================================================
# Config & Options
# ================================================================


# ================================================================
# Makefiles
# ================================================================
install -d %{buildroot}%{_datadir}
install -d %{buildroot}%{_datadir}/r2corba
cp -a lib %{buildroot}%{_datadir}/r2corba
cp -a bin %{buildroot}%{_datadir}/r2corba
ln -sfn %{_libdir}/ruby/site_ruby/1.8/ridl/ridlc.rb %{buildroot}%{_bindir}/ridlc

# ================================================================
# Manuals
# ================================================================

# ================================================================
# clean
# ================================================================

%clean
rm -rf %{buildroot}

# ================================================================
# pre install
# ================================================================


# ================================================================
# post install
# ================================================================

%post
/sbin/ldconfig


# ================================================================
# pre uninstall
# ================================================================


# ================================================================
# post uninstall
# ================================================================

%postun
/sbin/ldconfig


# ================================================================
# files
# ================================================================

# ---------------- r2corba ----------------

%files
%defattr(-,root,root,-)

%doc README
%doc THANKS
%doc LICENSE
%{_bindir}/ridlc
%{ruby_sitelib}
%{ruby_sitearch}

%files devel
%defattr(-,root,root)
%{_datadir}/r2corba

# ================================================================
# changelog
# ================================================================

%changelog
* Thu Jul 31 2008 Johnny Willemsen  <jwillemsen@remedy.nl> - 5.6.6-2
- Removed ace-tao-unusedarg.patch (related to bug #3270).

