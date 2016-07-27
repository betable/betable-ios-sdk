#!/usr/bin/perl
# Welcome to Matt's build script.  It's a howitzer so keep a close eye on everything it does.
# Lootwinner expressed concern I did a build where not all "sources" were the same, so this
# not only endeavours to make everything the same, but it caters to the fact I'm lazy.

# MAKE SURE ALL THE CHANGES YOU WANT FOR A REALEASE ARE ON MASTER AND COMITTED TO GITHUB 
# BEFORE RUNNING -- YOU WILL BE AT RELEASE BY THE END

use strict;
use warnings;

use File::Slurp;
use File::Copy::Recursive qw( dircopy );
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use Browser::Open qw( open_browser );

my $version = $ARGV[0] || '';

# version may be prefixed by a v--it required 3 numbers, separated by periods,
# and any amount of text thereafter for stuff like like 'pre' or 'beta'
unless ( $version =~ m/^v?(\d+\.\d+\.\d.*)/ ) {
    die "Unable to use version: $version\n";
}

# strip any v prefix
$version = $1;

# But ensure there is a v for tagging
my $tag_version = "v$version";

# Short name for where all the build stuff goes
my $publish_name = "BetableFramework-$version";

# Proper relative name for where the build stuff goes
my $publish_directory = "framework/$publish_name";

# this may start as a directory, but by the end it will be a symlink to the publish directory
my $latest_directory = "framework/Latest";

# Construct multiline replacement for regex later with here-doc named UPDATE
my $update = <<"UPDATE";
# Changelog

## $version [Download](https://github.com/betable/betable-ios-sdk/releases/download/${tag_version}/${publish_name}.zip)

UPDATE

# Notify user and bolt user's unput onto update
print
"Add the changelog features of this release to README.md, Ctrl+D when done:\n";
my $user_md_update = '';
while (1) {
    last if eof STDIN;
    $user_md_update .= scalar <STDIN>;
}

# Update README.md
my $readme_file = 'README.md';
my $readme_contents = read_file($readme_file);

# Abuse the position of the "# Changelog" text in the README to insert all the happy update info
$readme_contents =~ s/\# Changelog/${update}${user_md_update}/s;
write_file( $readme_file, $readme_contents );

# create and fill the stuff for the requested version
mkdir($publish_directory);
dircopy( 'Betable.framework', "${publish_directory}/Betable.framework" )
  or die $!;
dircopy(
    "${latest_directory}/Betable.bundle",
    "${publish_directory}/Betable.bundle"
) or die $!;

# Set up latest
unlink( \1, $latest_directory );
symlink( $publish_name, $latest_directory );

# Bundle the latest
my $zip_file = $publish_directory . '.zip';
my $zip      = Archive::Zip->new();
$zip->addDirectory( $publish_directory, $publish_name );
unless ( $zip->writeToFileNamed($zip_file) == AZ_OK ) {
    die "error writing $zip_file";
}

# mush all the stuff this script just did into git and tag it for release
system( 'git', 'add', $readme_file, $publish_directory, $latest_directory, $zip_file );
system( 'git', 'commit', '-m',     "Publishing $tag_version" );
system( 'git', 'tag', $tag_version );
system( 'git', 'push',   'origin', $tag_version );

# TODO oauth our way into api.github.com and automate the last bit here...

# open window to create this release
open_browser('https://github.com/betable/betable-ios-sdk/releases/new');

# open zip file in finder for gihub release
system( 'open', '-R', $zip_file );

print "$tag_version ready for release\n";
