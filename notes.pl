#!/usr/bin/env perl
use strict;
use warnings;
use File::Path qw(make_path remove_tree);
use File::Basename;
use POSIX qw(strftime);
use IPC::Open3;
use File::Spec;
use Cwd qw(abs_path);
use Getopt::Long;
use IO::Handle;

# Configuration
my $BASEDIR = "$ENV{HOME}/Notes";
my $NOTES_SH_CACHE = "$ENV{HOME}/.cache/notes.sh";
my $EXPORT_DIR = "$NOTES_SH_CACHE/export";
my $EDITOR = $ENV{EDITOR} || 'vim';

# Helpers
sub uuid {
    open(my $urandom, '<', '/dev/urandom') or die "Can't open /dev/urandom: $!";
    my $data;
    read($urandom, $data, 16);
    my @bytes = unpack('C*', $data);
    $bytes[6] = ($bytes[6] & 0x0f) | 0x40;
    $bytes[8] = ($bytes[8] & 0x3f) | 0x80;
    return sprintf("%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x",
        @bytes);
}

sub canonicalize {
    my ($name) = @_;
    $name = lc $name;
    $name =~ s/[^a-z0-9]/_/g;
    return $name;
}

sub utc_timestamp {
    return strftime("%Y%m%d%H%M%S", gmtime);
}

sub ensure_dirs {
    make_path($BASEDIR) unless -d $BASEDIR;
    make_path($NOTES_SH_CACHE) unless -d $NOTES_SH_CACHE;
    make_path($EXPORT_DIR) unless -d $EXPORT_DIR;
}

sub find_file_by_id {
    my ($id) = @_;
    my $cmd = qq{grep -l -r -m1 '^X-Note-Id: $id\$' $BASEDIR};
    my @files = sort qx{$cmd};
    chomp @files;
    return $files[0];
}

sub assert_find_file_by_id {
    my ($id) = @_;
    my $file = find_file_by_id($id);
    die "Note with ID <$id> not found\n" unless -f $file;
    return $file;
}

sub list_entries {
	my @entries;

    for my $file (glob("$BASEDIR/*/note.md")) {
        my ($message_id, $subject, $date);

        open(my $fh, '<', $file) or next;
        while (<$fh>) {
            chomp;
            $message_id = $1 if /^X-Note-Id:\s*(.+)/;
            $subject    = $1 if /^Subject:\s*(.+)/;
            $date       = $1 if /^X-Date:\s*(.+)/;
        }
        close($fh);

        if ($message_id && $subject && $date) {
            push @entries, "$subject $message_id";
        }
    }

    print join("\n", sort @entries), "\n";
}

sub new_entry {
    my ($name) = @_;
    die "Missing name for new entry\n" unless $name;
    my $canonical = canonicalize($name);
    my $full_name = "$canonical-" . utc_timestamp();
    my $note_id = uuid();
    my $note_dir = "$BASEDIR/$full_name";
    my $note_file = "$note_dir/note.md";

    make_path($note_dir);
    open(my $fh, '>', $note_file) or die "Can't write note: $!";
    my $timestamp = strftime("%Y-%m-%dT%H:%M:%SZ", gmtime);
    print $fh "X-Date: $timestamp\nX-Note-Id: $note_id\nSubject: $name\n\n";
    close($fh);

    system($EDITOR, $note_file);
}

sub edit_entry {
    my ($id) = @_;
    my $file = assert_find_file_by_id($id);
    system($EDITOR, $file);
}

sub fzf_entry {
    my @entries = list_entries_raw();  # Get list of unsorted entries
    return unless @entries;

    my $selected;
    open(my $fzf, '|-', 'fzf > /tmp/fzf_selection') or die "Can't run fzf";
    print $fzf join("\n", @entries);
    close($fzf);

    return unless -s "/tmp/fzf_selection";

    open(my $sel_fh, '<', '/tmp/fzf_selection') or die $!;
    chomp($selected = <$sel_fh>);
    close($sel_fh);

    my ($date, $id, $subject) = split(/\|/, $selected, 3);
    my $path = find_note_by_id($id);
    if ($path && -f $path) {
        system($ENV{EDITOR} // 'vi', $path);
    } else {
        print "No relevant note found.\n";
    }
}

sub list_entries_raw {
    my @entries;

    for my $file (glob("$BASEDIR/*/note.md")) {
        my ($message_id, $subject, $date);

        open(my $fh, '<', $file) or next;
        while (<$fh>) {
            chomp;
            $message_id = $1 if /^X-Note-Id:\s*(.+)/;
            $subject    = $1 if /^Subject:\s*(.+)/;
            $date       = $1 if /^X-Date:\s*(.+)/;
        }
        close($fh);

        if ($message_id && $subject && $date) {
	    push @entries, "$subject|$message_id";
        }
    }

    return @entries;
}

sub find_note_by_id {
    my ($uuid) = @_;
    for my $file (glob("$BASEDIR/*/note.md")) {
        open(my $fh, '<', $file) or next;
        while (<$fh>) {
            return $file if /^X-Note-Id:\s*\Q$uuid\E/;
        }
        close($fh);
    }
    return;
}

sub fzf_delete {
    my @entries = list_entries_raw();
    return unless @entries;

    my $selected;
    open(my $fzf, '|-', 'fzf > /tmp/fzf_selection') or die "Can't run fzf";
    print $fzf join("\n", @entries);
    close($fzf);

    return unless -s "/tmp/fzf_selection";

    open(my $sel_fh, '<', '/tmp/fzf_selection') or die $!;
    chomp($selected = <$sel_fh>);
    close($sel_fh);

    my ($subject, $id) = split(/\|/, $selected, 2);
    my $path = find_note_by_id($id);
    if ($path && -f $path) {
        print "Are you sure you want to delete: \"$subject\"? [y/N] ";
        chomp(my $confirm = <STDIN>);
        if (lc($confirm) eq 'y') {
            system('rm', '-rf', $path);
            print "Deleted.\n";
        } else {
            print "Cancelled.\n";
        }
    } else {
        print "No note found to delete.\n";
    }
}

sub export_note {
    my ($id) = @_;
    my $file = assert_find_file_by_id($id);
    open(my $in, '<', $file) or die "Can't open note: $!";
    my $basename = basename(dirname($file));
    my $export_file = "$EXPORT_DIR/$basename.md";
    open(my $out, '>', $export_file) or die "Can't export to $export_file: $!";

    while (<$in>) {
        print $out $_ unless /^X-(Date|Note-Id):/;
    }

    close($in);
    close($out);
    print "Exported to $export_file\n";
}

sub usage {
    print <<'USAGE';
Hello master \(^o^)/
Usage: notes.pl [options]
  --new NAME        Create new note
  --list            List notes
  --edit ID         Edit note by ID
  --fzf             Fuzzy find and edit by subject
  --delete          Fuzzy find and delete a note
  --export ID       Export note to markdown
  --help            Show this help
USAGE
    exit 1;
}

# Main
ensure_dirs();
my ($new, $list, $edit, $fzf, $delete, $export, $help);

GetOptions(
    'new=s'    => \$new,
    'list'     => \$list,
    'edit=s'   => \$edit,
    'fzf'      => \$fzf,
    'delete'   => \$delete,
    'export=s' => \$export,
    'help'     => \$help,
) or usage();

if ($help)        { usage() }
elsif ($new)      { new_entry($new) }
elsif ($list)     { list_entries() }
elsif ($edit)     { edit_entry($edit) }
elsif ($fzf)      { fzf_entry($fzf) }
elsif ($delete)   { fzf_delete() }
elsif ($export)   { export_note($export) }
else              { usage() }

