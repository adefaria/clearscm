#!/usr/bin/env perl
use strict;
use warnings;
use File::Find;
use File::Basename;
use Cwd qw(abs_path);

my $target_dir = shift // '.';
my @exts        = qw(.flac .mp3 .m4a .ogg);
my @cover_names = qw(cover.jpg cover.jpeg folder.jpg folder.png cover.png);
my %valid_ext   = map { lc($_) => 1 } @exts;

# Step 1: Collect and group audio files by directory
my %dir_files;
find({
    wanted => sub {
        return if -d $File::Find::name;
        my ($ext) = $_ =~ /(\.[^.]+)$/;
        return unless $ext && $valid_ext{lc($ext)};
        
        my $abs_file = abs_path($File::Find::name);
        my $dir      = dirname($abs_file);
        push @{$dir_files{$dir}}, $abs_file;
    },
    no_chdir => 1,
}, $target_dir);

# Step 2: Process each album directory
foreach my $dir (sort keys %dir_files) {
    my @dirs     = split('/', $dir);
    my $album    = pop @dirs;
    my $artist   = pop @dirs;

    $album  ||= "Unknown Album";
    $artist ||= "Unknown Artist";

    # Look for cover art in this directory
    my $found_cover = '';
    foreach my $cname (@cover_names) {
        my $test_path = "$dir/$cname";
        if (-f $test_path) {
            $found_cover = $test_path;
            last;
        }
    }

    my @sorted_files = sort @{$dir_files{$dir}};
    my $track_num = 1;

    print "\n--- Album: '$album' by '$artist' ---\n";

    foreach my $full_path (@sorted_files) {
        my ($filename, $d, $ext) = fileparse($full_path, qr/\.[^.]+$/);
        my $title = $filename;
        $title =~ s/^\s+|\s+$//g;

        print "  Track $track_num: '$title' ($ext)\n";

        my $exit_code;
        if (lc($ext) eq '.mp3') {
            # Use eyeD3 for MP3 files
            my @cmd = (
                'eyeD3',
                "--artist=$artist",
                "--album-artist=$artist",
                "--album=$album",
                "--title=$title",
                "--track=$track_num"
            );
            if ($found_cover && -f $found_cover) {
                push @cmd, "--add-image=$found_cover:FRONT_COVER";
            }
            push @cmd, $full_path;
            $exit_code = system(@cmd);
        } else {
            # Use exiftool for FLAC/M4A/OGG files
            my @cmd = (
                'exiftool',
                '-overwrite_original',
                "-Artist=$artist",
                "-AlbumArtist=$artist",
                "-Album=$album",
                "-Title=$title",
                "-Track=$track_num"
            );
            if ($found_cover && -f $found_cover) {
                push @cmd, "-Picture=$found_cover";
            }
            push @cmd, $full_path;
            $exit_code = system(@cmd);
        }

        if ($exit_code != 0) {
            warn "    [ERROR] Failed to tag $filename$ext (Exit code: $exit_code)\n";
        }

        $track_num++;
    }
}

print "\nRecursive tagging and auto-numbering complete.\n";
