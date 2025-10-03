#!/usr/bin/env perl
use strict;
use warnings;
use File::Path qw(make_path);
use File::Spec;
use Cwd 'abs_path';

my $home    = $ENV{HOME};
my $notes   = File::Spec->catdir($home, "Notes");
my $localbin = File::Spec->catdir($home, ".local", "bin");
my $script   = File::Spec->catfile($notes, "nop.pl");
my $symlink  = File::Spec->catfile($localbin, "nop");

# 1. Create ~/Notes directory if missing
unless (-d $notes) {
    print "Creating $notes...\n";
    make_path($notes) or die "Failed to create $notes: $!";
}

# 2. Ensure ~/.local/bin exists
unless (-d $localbin) {
    print "Creating $localbin...\n";
    make_path($localbin) or die "Failed to create $localbin: $!";
}

# 3. If nop.pl doesn’t exist, create a stub script
my $cwd_script = File::Spec->catfile('.', 'nop.pl');
if (-f $cwd_script) {
    # Use the one in the current directory
    $script = abs_path($cwd_script);
    print "Using existing $script from current directory\n";
} else {
    # Fall back to ~/Notes/nop.pl
    $script = File::Spec->catfile($notes, "nop.pl");
    unless (-f $script) {
        print "Creating sample $script...\n";
        open my $fh, ">", $script or die "Cannot create $script: $!";
        print $fh <<"EOF";
#!/usr/bin/env perl
use strict;
use warnings;
print "Hello from nop!\\n";
EOF
        close $fh;
    }
}

# 4. Make nop.pl executable
chmod 0755, $script or warn "Could not chmod $script: $!";

# 5. Create or replace symlink ~/.local/bin/nop
if (-l $symlink or -f $symlink) {
    unlink $symlink or warn "Could not remove old symlink $symlink: $!";
}
symlink $script, $symlink or die "Failed to symlink $script to $symlink: $!";

print "Setup complete. You can now run 'nop' from your shell.\\n";

