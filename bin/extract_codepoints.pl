#!/usr/bin/perl -w
#
# vim: set et ts=4 sw=4 ai si:
#
# Work through a set of language subdirectories, find all *.po files and build
# several sets of used codepoints. E.g., a Japanese font does only need the
# codepoints used in subdirectory "ja", but not the ones used in other
# (overlapping because of Unicode Han-Unification) CJK translations like
# "zh_CN", "zh_TW" etc.
#
# The resulting list of used codepoints for each font will be used to generate
# stripped-down versions of fonts that only include glyphs for the code-points
# that are needed to display the texts of the installation-system. (This way
# better fonts can be used and still fit into the installation system
# ram-disk.)
#
# To make the display of mixed-font texts possible, the Qt Toolkit that is
# used in the graphical installation system is configured with a list of
# fonts, and Qt then selects the first font in the list that contains a key
# character for a given range to display codepoints in that range.
#
# Thus, the "@fontspec"-table below in this program needs to take into account
# the codepoint-ranges that Qt uses. E.g. there is no point in having two
# fonts the contain glyphs for different codepoint-ranges of the Japanese Han
# characters, since Qt uses only the first font it finds in the list that has
# 0x4e00 (the character for "one" (Japanese: ichi)) for the whole range of
# Japanese Han characters.
#
# FIXME : the key character that triggers the recognition of a range in a
# specific font inside Qt *always* needs to be included in the target font
# (maybe even if no other code-points in that range are being used?).
#
# The resulting fonts will be handled as a font replacement stack by Qt. 
#
# FIXME : write more here as program matures; also, write better and more
# accurately
#
# $Id: extract_codepoints.pl,v 1.4 2004/04/07 12:48:04 odabrunz Exp $
#
# 2004 Olaf Dabrunz
#

my $debug=1;
my $path=".";

my @dirs = ();

use strict;
use File::Find;
use vars qw($opt_d $opt_l $opt_t);
use Getopt::Std;

binmode STDOUT, ":utf8";


$0 =~ m/([^\/]*)$/;
my $progname = $1;

# Usage message
sub usage {
    print <<EOF;
$progname version 0.9
Extracts the Unicode UTF-8 character codes used in "gettext" message files.

$progname [-d <selector>] [-l <lang_dir>]

Options:
    -d <selector>           set debugging selector (defaults to $debug)
    -l <lang_dir>           only process this language subdirectory (defaults
                            to all configured languages (see \@dirs in the source))
    -t <top-level-dir>      set top-level directory of the translation tree
                            (defaults to '$path')
EOF
}

# parse command line options
if (! getopts('d:l:t:')) { usage; exit 1; }
if (defined $opt_d) { $debug = $opt_d; }
if (defined $opt_l) { @dirs = ( $opt_l ); }
if (defined $opt_t) { $path = ( $opt_t ); }

# expand "~"-constructs in pathname
$path =~ s{ ^ ~ ( [^/]* ) }
          { $1
                ? (getpwnam($1))[7]
                : ( $ENV{HOME} || $ENV{LOGDIR} || (getpwuid($>))[7] )
          }ex;

chdir($path) or die "cannot change to directory $path: $!\n";

# find all language subdirectories of the form [a-z][a-z](_[A-Z][A-Z]|)
# (this is currently unused...)

if (! defined $opt_l) {
    opendir(DIR, ".")     or die "cannot open directory '.': $!\n";

    @dirs = map  { $_->[1] }        
            grep { -d $_->[1] }
            map  { [ $_, "$path/$_" ] }        
            grep { /^[a-z][a-z](_[A-Z][A-Z]|)$/ }
            readdir(DIR);

    closedir(DIR);

    # BUT, at the moment only the following translations are ready and will be
    # included (FIXME : this list is not checked!)
    @dirs = ( 'ja', 'cy', 'es', 'fi', 'it', 'nl', 'ro', 'sl_SI', 'zh', 'bg', 'cs',
        'en_GB', 'fr', 'hu', 'no', 'pt', 'ru', 'sv', 'tr', 'zh_CN', 'bs', 'de',
        'en_US', 'gl', 'id', 'ko', 'nb', 'pl', 'pt_BR', 'sk', 'ta', 'tv', 'zh_TW');
}


# These are the language directories we have to parse for a given font file
# name prefix; also, the coderanges that are extracted at the end for this
# font are given here.
# FIXME :
# - what is the correct name for SuSESans?
# - any fonts missing or misclassified?
# - how do I handle directory "zh"; is it obsolete?
# - should we always map Kana (3040-30FF) to a Japanese font?
#   No, because the would not look nice together with a Chinese font.
#   Currently the Kana are at the wrong code positions in the AR PL fonts.
#   But we will fix this if necessary in the fonts.
# - should we always map Bopomofo (3100-312F, 31A0-31BF) to a Chinese font?
#   No, same argument as for Kana.
# - are there other ranges that should be statically assigned to a specific
#   font (e.g. 3200-327F -> Korean, 3280-33FF -> Japanese)?
#

my @fontspecs = (
    [ 'SuSESans'    ,  { map { $_ => 1 } @dirs }        , [ [ 0x0020, 0x036F ], [ 0x1E00, 0x1EFF ] ] ],
    [ 'FreeSans'    ,  { map { $_ => 1 } @dirs }        , [ [ 0x0370, 0x04FF ], [ 0x1F00, 0x1FFF ] ] ],
    [ 'kochi'       ,  { map { $_ => 1 } ('ja') }       , [ [ 0x2E80, 0x312F ], [ 0x3190, 0x9FFF ], [ 0xF900, 0xFAFF ] ] ],
#    [ 'bkai'        ,  { map { $_ => 1 } ('zh_TW') }    , [ [ 0x2E80, 0x312F ], [ 0x3190, 0x9FFF ], [ 0xF900, 0xFAFF ] ] ],
    [ 'bsmi'        ,  { map { $_ => 1 } ('zh_TW') }    , [ [ 0x2E80, 0x312F ], [ 0x3190, 0x9FFF ], [ 0xF900, 0xFAFF ] ] ],
#    [ 'gkai'        ,  { map { $_ => 1 } ('zh_CN') }    , [ [ 0x2E80, 0x312F ], [ 0x3190, 0x9FFF ], [ 0xF900, 0xFAFF ] ] ],
    [ 'gbsn'        ,  { map { $_ => 1 } ('zh_CN') }    , [ [ 0x2E80, 0x312F ], [ 0x3190, 0x9FFF ], [ 0xF900, 0xFAFF ] ] ],
    [ 'batang'      ,  { map { $_ => 1 } ('ko') }       , [ [ 0x3130, 0x318F ], [ 0xAC00, 0xD7FF ] ] ],
#    [ 'dotum'       ,  { map { $_ => 1 } ('ko') }       , [ [ 0x3130, 0x318F ], [ 0xAC00, 0xD7FF ] ] ],
#    [ 'gulim'       ,  { map { $_ => 1 } ('ko') }       , [ [ 0x3130, 0x318F ], [ 0xAC00, 0xD7FF ] ] ],
#    [ 'hline'       ,  { map { $_ => 1 } ('ko') }       , [ [ 0x3130, 0x318F ], [ 0xAC00, 0xD7FF ] ] ],
);

# create hash for dir -> fonts lookup
my %dirs_to_fonts = ( map { $_ => [] } @dirs );
my $x = ""; my $y = "";
foreach $x (@dirs) {
    foreach $y (@fontspecs) {
        my ($a, $b, $c) = @$y;
        if ( exists $b->{$x} ) {
            push @{$dirs_to_fonts{$x}}, $a;
        }
    }
}

# create hash for fontname -> @fontspecs entry number lookup
my %fname_to_fontspecs = ();
my $i = 0;
foreach $x (@fontspecs) {
    my ($font, $subdirs, $coderanges) = @$x;
    $fname_to_fontspecs{$font} = $i;
    $i++;
}

my @global_CPA = ();
my $unassigned = 'unassigned';
my %CPAs = ();
my $currentdir = "";

# ---------------------------------------------------------------------------
#
# Subroutines
#

sub debugprint {
    my ($string, $prefix, $color, $subsys, $hl) = @_;
    if ($debug & $subsys) {
        chomp $string;
        $string =~ s/($hl)/\e[31;01m$1\e[m$color/gi if defined $hl;
        print($color . $prefix . " <$string>\e[m\n");
    }
}

# Algorithm:
#
# 1. (Init) For each directory in "@dirs", create a list of fonts that contain
#    that directory in its list of fonts ("%dirs_to_fonts").
# 2. (Scan) Scan a source file. For each found code-point, put the name of the
#    language-part of the directory (e.g. 'ja') at the position of the
#    character-code into the code-point array. 
# 3. (Evaluation) After the scan, go through the list of code-points and for
#    every entry, for every language saved in it, put the code-point number
#    into the code-point array of every font that is in "%dirs_to_fonts" for
#    this language.
# 4. (Output) For each font, write an output file containing all the
#    code-points found in that font's code-point array.
#


# save the code-points of a string in the array-of-hashes @global_CPA

sub savecp {
    my ($string) = @_;
    my $uc = 0; my $i = 0;
    my $fspec = (); my $range = ();
    debugprint("$string\n", "        savecp:", "\e[01m", 4, undef);

    my $l = length($string);
    print "                " if $debug & 8;

    # For each character, add the current language directory to the code-point
    # in the global code-point array.
    for ( $i=0; $i<$l; $i++ ) {
        $uc = ord(substr($string, $i, 1));
        $global_CPA[$uc]{$currentdir}++;
        printf("%s: %#x ", substr($string, $i, 1), $uc) if $debug & 8;
    }
    print "\n" if $debug & 8;
}

# parse a line belonging to a msgstr-entry and add it to the codepoint array;
# concatenate C-style multiline strings and remove C-style "\[abfnrtv0]", while
# interpreting "\[\?'"]", "\o...", "\x..", "\u....", ("\U........" is missing,
# since Perl 5.8 does not yet support surrogates).
#
# FIXME : This is not a complete C-parser; e.g. it does not recognize comments
# (/* */, //), and thus strings in comments are seen and evaluated as normal
# strings. But this is not a major problem, since for syntactically correctly
# quoted strings (including strings in comments) it only produces false
# positives (and thereby maybe slightly expand the array of used code-points).

sub parse_string {
    ($_) = @_;
    chomp;
    debugprint("$_\n", "    parse_string:", "", 2, undef);
    s/^\s*msgstr(\[[^]]*\]|)\s*//io;

    my $instr=0; # are we between quotes?

    CPLOOP:
    {
        savecp("\""),           redo CPLOOP if $instr && /\G\\"/gco;
        $instr=0,               redo CPLOOP if $instr && /\G"/gco;
        $instr=1,               redo CPLOOP if !$instr && /\G"/gco;
                                redo CPLOOP if !$instr && /\G./gco;

        # the last case above handles all characters outside of quotes,
        # so below we can be sure to be within quotes
                                redo CPLOOP if /\G\\[abfnrtv0]/gco;
        savecp($1),             redo CPLOOP if /\G\\([\\?'])/gco;
        savecp(pack("C",oct($1))), redo CPLOOP if /\G\\o([0-7]{3})/gco;
        savecp(pack("C",hex($1))), redo CPLOOP if /\G\\x([0-9a-fA-F]{2})/gco;
        # FIXME : the following Unicode support is incomplete (long forms) and
        # may be wrong
        savecp(pack("U",hex($1))), redo CPLOOP if /\G\\u([0-9a-fA-F]{4})/gco;

        # everything that does not contain an initial character of any of the
        # "inside of quotes" cases above will be put into a string here and
        # codepoints will be saved for the whole string in one call
        savecp($1),             redo CPLOOP if /\G([^\\"]+)/gco;
    }
}

# parse a *.po file and extract the used UTF-8 codepoints in the gettext
# message strings

sub parse_file {
    # find passes the basename of the current file in $_
    my $file = $_;
    $currentdir = $File::Find::dir ;
    $currentdir =~ s,/.*$,, ;
    return unless ! -d $file && $file =~ /\.po$/io;
    debugprint("$File::Find::dir/$file\n", "parsing file", "", 1, undef);

    open(FH, "<:utf8", $file)   or die "unable to open file $file: $!";

    my $hl="(msgstr|msgid|^#*)";
    while( <FH> ) {
        debugprint("$_", "parse_file:", "\e[36m", 2, $hl);
        next unless $_ =~ /^\s*msgstr/io;
        parse_string($_);

        while( <FH> ) {
            debugprint("$_", "parse_file:", "\e[36m", 2, $hl);
            last unless $_ =~ /^\s*"/i || $_ =~ /^\s*msgstr/io;
            parse_string($_);
        }
    }
    close(FH);
}

# (Evaluation) After the scan, go through the list of code-points and for every
# entry, for every language saved in it, put the code-point number into the
# code-point array of every font that is in "%dirs_to_fonts" for this language.

sub evaluate_global_CPA {
    my $dir = ""; my $font = ""; my $range = (); my $i = 0;
    my $exists = 0; my $assigned = 0;

    print "assigning collected code-points to fonts...\n" if $debug & 1;
    for ( $i=0; $i <= 0xFFFF; $i++ ) {
        $assigned = 0; $exists = 0;
        foreach $dir (keys %{$global_CPA[$i]}) {
            $exists = 1;
            foreach $font (@{$dirs_to_fonts{$dir}}) {
                my ($font, $subdirs, $coderanges) = @{$fontspecs[$fname_to_fontspecs{$font}]};
                foreach $range (@$coderanges) {
                    my ($low, $high) = @$range;
                    if ($low <= $i && $i <= $high) {
                        @{$CPAs{$font}}[$i] = 1;
                        $assigned = 1;
                        last;
                    }
                }
            }
        }
        # remember codepoints we could not assign to any font
        if ($exists && !$assigned) { @{$CPAs{$unassigned}}[$i] = 1; };
    }
}

# Dump code-point arrays to files (<font>.ucp)

sub dump_CPAs {
    my $fspec = (); my $range = ();
    my $i = 0; my $count = 0; my $fontcount = 0;
    my $fname = "";

    foreach $fspec (@fontspecs, [$unassigned, {}, []] ) {
        my ($font, $subdirs, $coderanges) = @$fspec;
        printf("\n\n\e[31;01mFont: %s\e[m\n\n", $font) if $debug & 32;

        $fname = $font . ".ucp";
        open(FH, ">:utf8", $fname)   or die "unable to open file $fname: $!";

        $fontcount = 0;
        for ( $i=0; $i <= 0xFFFF; $i++ ) {
            if (@{$CPAs{$font}}[$i]) {
                $count++; $fontcount++;
                if ($debug & 32) {
                    if ($debug & 16) {
                        if ($font ne $unassigned) {
                            printf("%#4.4x %s\n", $i, chr($i));
                        } else {
                            printf("%#4.4x %s", $i, chr($i)); map { printf("  %s: %s", $_,  $global_CPA[$i]{$_}); } keys %{$global_CPA[$i]}; print "\n";
                        }
                    } else {
                        printf("%#4.4x\n", $i);
                    }
                }
                if ($font ne $unassigned) {
                    printf(FH "%#4.4x %s\n", $i, chr($i));
                } else {
                    printf(FH "%#4.4x %s", $i, chr($i)); map { printf(FH "  %s: %s", $_,  $global_CPA[$i]{$_}); } keys %{$global_CPA[$i]}; print FH "\n";
                }
            }
        }

        close(FH);
        print "\n" if $debug & 32;
        print "used codepoints in font \"$font\": $fontcount\n";
    }

    print "\n" if $debug & 32;
    print "total used codepoints: $count\n";
}

# ---------------------------------------------------------------------------
#
# Main program
#

# Main loop over all files
find( \&parse_file, @dirs );

# assign code-points to fonts
evaluate_global_CPA();

# dump output to files
dump_CPAs();


