
use warnings;
use strict;

package CPAN::Site;
use base 'CPAN';

my $reload_orig;
BEGIN {
  $reload_orig = \&CPAN::Index::reload;
}

# Add "CPAN" to the list of exported items
sub import
{  my $class  = shift;
   unshift @_, 'CPAN';

   my $import = CPAN->can('import');
   goto &$import;
}

CPAN::Config->load if CPAN::Config->can('load');

if(my $urls = $ENV{CPANSITE})
{   unshift @{$CPAN::Config->{urllist}}, split ' ', $urls;
}

my $last_time = 0;

no warnings 'redefine';
sub CPAN::Index::reload {
   my($cl,$force) = @_;
   my $time = time;

   # Need this code duplication since reload does not return something
   # meaningful

   my $expire = $CPAN::Config->{index_expire};
   $expire = 0.001 if $expire < 0.001;

   return if $last_time + $expire*86400 > $time
          && !$force;

   $last_time = $time;

   my $needshort = $^O eq "dos";

   $reload_orig->(@_);

   $cl->rd_modpacks(
     $cl->reload_x( "site/02packages.details.txt.gz"
                  , ($needshort ? "12packag.gz" : "")
                  , $force));
   $cl->rd_authindex(
     $cl->reload_x( "site/01mailrc.txt.gz"
                  , ($needshort ? "11mailrc.gz" : "")
                  , $force));

   # CPAN Master overwrites?
   $reload_orig->(@_);
}

1;

__END__

=head1 NAME

CPAN::Site - CPAN.pm subclass for adding site local modules

=head1 SYNOPSIS

  perl -MCPAN::Site -e shell
  cpansite shell                # alternative

  perl -MCPAN::Site -e 'install AnyModule'
  cpansite install AnyModule    # alternative

=head1 DESCRIPTION

This module adds access to site specific modules to the CPAN.pm install
interface. The general idea is to have a local (pseudo) CPAN server which
is asked first. If the request fails -which is the usual case-, CPAN.pm
switches to the next URL in the list pointing to a real CPAN server.

=head1 SEE ALSO

Read the manual page for the C<cpansite(1)> script for all details.

=head1 AUTHOR

Mark Overmeer E<lt>perl@overmeer.netE<gt>,
Based on the original module by Ulrich Pfeifer E<lt>pfeifer@wait.deE<gt>.

=cut
