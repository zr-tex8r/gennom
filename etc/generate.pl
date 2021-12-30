use v5.12;
use utf8;
use File::Copy 'copy';
use ZRTeXtor ':all';
my $program = 'generate';
my $tempb = '__ggnm';
my $tempz = 'zzggnm';

# TeX font family name
my $font_name = 'gennom';
# where 'texucsmapping' repository is checked out
my $tum_dir = "$ENV{ZR_PRIVATE_WORK}/texlabo/texucsmapping";
# The scale value for Cochineal.
my $scale = 1.106;

my @target_enc = qw( OT1 T1 LY1 TS1 );
my $gennom_ttf_file = 'GenEiNombre.ttf';

sub cochineal_name {
  my ($enc) = @_;
  my $mid = ($enc eq 'TS1') ? '' : 'lf-';
  return 'Cochineal-Roman-' . $mid . lc($enc);
}

my (%texenc, @urow, %rawpl);
# Glyphs for this Unicode range are picked from GenEi Nombre.
my @pickup_ucs = (
  0x0020 .. 0x0040,
  0x005B .. 0x0060,
  0x007B .. 0x007E,
  0x00A5 .. 0x00A7,
  0x00B0 .. 0x00B1,
  0x00B5, 0x00D7, 0x00F7,
  0x0391 .. 0x03A1,
  0x03A3 .. 0x03A9,
  0x2010 .. 0x2011,
  0x2013 .. 0x2015,
  0x2018 .. 0x201A,
  0x201C .. 0x201E,
  0x2020 .. 0x2022,
  0x2026, 0x2030,
);

sub main {
  read_encoding();
  copy(kpse($gennom_ttf_file), "$tempz-g.ttf");
  generate_raw_tfm();
  foreach (@target_enc) {
    generate_vf($_);
  }
  unlink(glob("$tempb-*.*"), glob("$tempz-*.*"));
}

sub read_encoding {
  local ($_);
  foreach my $enc (@target_enc) {
    info("load encoding", $enc);
    my @vec; $#vec = 255; $texenc{$enc} = \@vec;
    $_ = lc($enc); $_ = "$tum_dir/bx-$_.txt";
    open(my $h, '<', $_) or error("cannot open", $_);
    while (<$h>) {
      s/\#.*//; s/\s+\z//;
      my ($t, $u) = split(m/\t/, $_);
      $vec[hex($t)] = hex($u);
    }
    close($h);
  }
}

sub generate_raw_tfm {
  local ($_); my (%curow);
  system("ttf2tfm $tempz-g.ttf $tempz-u\@Unicode\@ 1>$tempb-0.out");
  ($? == 0) or error("ttf2tfm failure");
  foreach my $uc (@pickup_ucs) {
    my $urow = int($uc / 256);
    (!exists $curow{$urow}) or next; $curow{$urow} = 1;
    my $sfx = sprintf("u%02x", $urow);
    my ($src, $dst) = ("$tempz-$sfx", "r-$font_name-r-$sfx");
    (-f "$src.tfm") or next;
    info("generate raw TFM", $sfx);
    $_ = read_whole_file("$src.tfm", 1) or error();
    my $pl = x_tftopl($_) or error();
    #
    my @cpl;
    foreach my $e (@$pl) {
      $_ = $e->[0];
      if (m/^(HEADER|COMMENT|CHECKSUM)$/) {
        next;
      } elsif (m/^FAMILY$/) {
        $e->[1] = $font_name;
      } elsif (m/^CODINGSCHEME$/) {
        $e->[1] = uc("unicode-$sfx");
      }
      push(@cpl, $e);
    }
    #
    write_whole_file("$dst.tfm", x_pltotf(\@cpl), 1) or error();
    push(@urow, $urow); $rawpl{$urow} = \@cpl;
  }
}

sub generate_vf {
  my ($enc) = @_; local ($_);
  info("generate VF", $enc);
  my $sfx = lc($enc);
  my ($src, $dst) = (cochineal_name($enc), "$font_name-r-$sfx");
  my $pl = x_tftopl(read_whole_file(kpse("$src.tfm"), 1)) or error();
  #
  my %fidx = map { $urow[$_] => $_ + 1 } (0 .. $#urow);
  my (%vec, %pick);
  foreach my $urow (@urow) {
    my @vec; $vec{$urow} = \@vec;
    foreach my $e (@{$rawpl{$urow}}) {
      if ($e->[0] eq 'CHARACTER') {
        $vec[pl_value($e, 1)] = [ @{$e}[3..$#$e] ];
      }
    }
  }
  %pick = map { $_ => 1 } (@pickup_ucs);
  my @cpl = (['VTITLE', uc($font_name)],
    ['MAPFONT', 'D', $fidx{$_},
      ['FONTNAME', $src],
      ['FONTAT', 'R', $scale]],
    map {['MAPFONT', 'D', $fidx{$_},
      ['FONTNAME', sprintf("r-$font_name-r-u%02x", $_)],
      ['FONTAT', 'R', 1]]
    } (@urow));
  L1:foreach my $e (@$pl) {
    $_ = $e->[0];
    if (m/^(COMMENT|CHECKSUM)$/) {
      next;
    } elsif (m/^FAMILY$/) {
      $e->[1] = $font_name;
    } elsif (m/^(FONTDIMEN|LIGTABLE)$/) {
      scale_dimen($e);
      foreach my $ee (@$e) {
        if (ref $ee && $ee->[0] eq 'QUAD') {
          pl_set_value($ee, 1, 1 << 20);
        }
      }
    } elsif (m/^(CHARACTER)$/) {
      my $tc = pl_value($e, 1);
      my $uc = $texenc{$enc}[$tc];
      if (defined $uc && $pick{$uc}) {
        #info("use GenEiNombre", $tc);
        my ($urow, $cc) = ($uc >> 8, $uc & 255);
        my $r = $vec{$urow}[$cc] or error("NO VEC", $uc);
        $#$e = 2; push(@$e, @$r);
        push(@$e, ['MAP',
          ['SELECTFONT', 'D', $fidx{$urow}],
          ['SETCHAR', 'D', $cc]]);
      } else {
        scale_dimen($e);
        push(@$e, ['MAP', ['SETCHAR', 'D', $tc]]);
      }
    }
    push(@cpl, $e);
  }
  #
  my ($cvf, $ctfm) = x_vptovf(\@cpl) or error();
  write_whole_file("$dst.vf", $cvf, 1) or error();
  write_whole_file("$dst.tfm", $ctfm, 1) or error();
}

sub is_real_number {
  my ($e, $k) = @_; local $_ = $e->[$k];
  return (ref $_ eq 'ARRAY' && $_->[0] eq ' ' && $_->[2] eq 'R');
}

sub scale_dimen {
  my ($e) = @_; local ($_);
  (ref $e) or return;
  foreach my $k (0 .. $#$e) {
    if (is_real_number($e, $k)) {
      $_ = pl_value($e, $k, 1);
      pl_set_value($e, $k, $_ * $scale);
    } else {
      scale_dimen($e->[$k]);
    }
  }
}

sub info {
  say STDERR (join(": ", $program, ((@_) ? (@_) : textool_error())));
}
sub error {
  info(@_); exit(1);
}

sub kpse {
  my ($f) = @_;
  local $_ = `kpsewhich $f`; chomp($_);
  ($_ ne '') or error("not found", $f);
  return $_;
}

main();
