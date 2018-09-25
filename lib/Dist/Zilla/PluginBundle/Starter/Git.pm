package Dist::Zilla::PluginBundle::Starter::Git;

use Moose;
extends 'Dist::Zilla::PluginBundle::Starter';
use namespace::clean;

our $VERSION = 'v3.0.0';

has '+revision' => (
  default => sub { $_[0]->payload->{revision} // 3 },
);

before configure => sub {
  my ($self) = @_;
  my $name = $self->name;
  die "[$name] requires at least revision 3\n" unless $self->revision >= 3;
};

sub gather_plugin { 'Git::GatherDir' }

my @allow_dirty = qw(dist.ini Changes);

sub pluginset_release_management {
  my ($self) = @_;
  my $versions = $self->managed_versions;
  my @copy_files = @{$self->copy_from_release};
  my @plugins;
  push @plugins, ['Git::Check' => {allow_dirty => [@allow_dirty]}];
  push @plugins, 'RewriteVersion',
    [NextRelease => { format => '%-9v %{yyyy-MM-dd HH:mm:ss VVV}d%{ (TRIAL RELEASE)}T' }]
    if $versions;
  push @plugins,
    [CopyFilesFromRelease => { filename => [@copy_files] }],
    ['Regenerate::AfterReleasers' => { plugin => $self->name . '/CopyFilesFromRelease' }],
    if @copy_files;
  push @plugins,
    ['Git::Commit' => 'Release_Commit' => { allow_dirty => [@allow_dirty, @copy_files], add_files_in => '/' }],
    'Git::Tag';
  push @plugins, 'BumpVersionAfterRelease',
    ['Git::Commit' => 'Version_Bump_Commit' => { allow_dirty_match => '^', commit_msg => 'Bump version' }]
    if $versions;
  push @plugins, 'Git::Push';
  return @plugins;
}

__PACKAGE__->meta->make_immutable;
1;

=head1 NAME

Dist::Zilla::PluginBundle::Starter::Git - A minimal Dist::Zilla plugin bundle with git support

=head1 SYNOPSIS

  ; dist.ini
  name    = My-Cool-Distribution
  author  = Example Jones <jones@example.com>
  license = Perl_5
  copyright_holder = Example Jones
  copyright_year   = 2017
  version = 0.001
  
  [@Starter::Git]      ; all that is needed to start
  revision = 3         ; always defaults to revision 3
  
  ; configuring examples
  installer = ModuleBuildTiny
  -remove = Pod2Readme ; to use [Readme::Brief] instead, for example
  ExecDir.dir = script ; change the directory used by [ExecDir]
  managed_versions = 1 ; uses the main module version, and bumps module versions after release

=head1 DESCRIPTION

The C<[@Starter::Git]> plugin bundle for L<Dist::Zilla> is a subclass of the
L<[@Starter]|Dist::Zilla::PluginBundle::Starter> plugin bundle designed to
support a Git-based workflow. See the documentation for C<[@Starter]> for any
details not listed here.

For one-line initialization of a new C<[@Starter::Git]>-based distribution, try
L<Dist::Zilla::MintingProfile::Starter::Git>.

=head1 OPTIONS

C<[@Starter::Git]> inherits the options from
L<[@Starter]|Dist::Zilla::PluginBundle::Starter>, and can similarly be further
configured by the composed roles, as in L</"CONFIGURING">.

=head2 revision

  [@Starter::Git]
  revision = 3

As in L<Dist::Zilla::PluginBundle::Starter/"revision">, but defaults to
revision 3. C<[@Starter::Git]> requires at least revision 3.

=head2 installer

As in L<Dist::Zilla::PluginBundle::Starter/"installer">.

=head2 managed_versions

As in L<Dist::Zilla::PluginBundle::Starter/"managed_versions">, and
additionally uses L<[Git::Commit]|Dist::Zilla::Plugin::Git::Commit> a second
time after L<[BumpVersionAfterRelease]|Dist::Zilla::Plugin::BumpVersionAfterRelease>
to commit the bumped versions (with the plugin name C<Version_Bump_Commit>).

=head2 copy_from_release

As in L<Dist::Zilla::PluginBundle::Starter/"copy_from_release">, and allows the
copied files to have uncommitted changes during the C<Release_Commit>.

=head1 REVISIONS

The C<[@Starter::Git]> plugin bundle supports the following revisions.

=head2 Revision 3

Revision 3 is the default and is equivalent to using the following plugins:

=over 2

=item L<[Git::GatherDir]|Dist::Zilla::Plugin::Git::GatherDir>

=item L<[MetaYAML]|Dist::Zilla::Plugin::MetaYAML>

=item L<[MetaJSON]|Dist::Zilla::Plugin::MetaJSON>

=item L<[License]|Dist::Zilla::Plugin::License>

=item L<[Pod2Readme]|Dist::Zilla::Plugin::Pod2Readme>

=item L<[PodSyntaxTests]|Dist::Zilla::Plugin::PodSyntaxTests>

=item L<[Test::ReportPrereqs]|Dist::Zilla::Plugin::Test::ReportPrereqs>

=item L<[Test::Compile]|Dist::Zilla::Plugin::Test::Compile>

  xt_mode = 1

=item L<[MakeMaker]|Dist::Zilla::Plugin::MakeMaker>

=item L<[Manifest]|Dist::Zilla::Plugin::Manifest>

=item L<[PruneCruft]|Dist::Zilla::Plugin::PruneCruft>

=item L<[ManifestSkip]|Dist::Zilla::Plugin::ManifestSkip>

=item L<[RunExtraTests]|Dist::Zilla::Plugin::RunExtraTests>

=item L<[Git::Check]|Dist::Zilla::Plugin::Git::Check>

  allow_dirty = dist.ini
  allow_dirty = Changes

=item L<[TestRelease]|Dist::Zilla::Plugin::TestRelease>

=item L<[ConfirmRelease]|Dist::Zilla::Plugin::ConfirmRelease>

=item L<[UploadToCPAN]|Dist::Zilla::Plugin::UploadToCPAN>

=item L<[Git::Commit / Release_Commit]|Dist::Zilla::Plugin::Git::Commit>

  allow_dirty = dist.ini
  allow_dirty = Changes
  add_files_in = /

=item L<[Git::Tag]|Dist::Zilla::Plugin::Git::Tag>

=item L<[Git::Push]|Dist::Zilla::Plugin::Git::Push>

=item L<[MetaConfig]|Dist::Zilla::Plugin::MetaConfig>

=item L<[MetaNoIndex]|Dist::Zilla::Plugin::MetaNoIndex>

  directory = t
  directory = xt
  directory = inc
  directory = share
  directory = eg
  directory = examples

=item L<[MetaProvides::Package]|Dist::Zilla::Plugin::MetaProvides::Package>

  inherit_version = 0

=item L<[ShareDir]|Dist::Zilla::Plugin::ShareDir>

=item L<[ExecDir]|Dist::Zilla::Plugin::ExecDir>

=back

This revision differs from L<[@Basic]|Dist::Zilla::PluginBundle::Basic> as
follows:

=over 2

=item *

Uses L<[Git::GatherDir]|Dist::Zilla::Plugin::Git::GatherDir>
instead of L<[GatherDir]|Dist::Zilla::Plugin::GatherDir>.

=item *

Uses L<[ReadmeAnyFromPod]|Dist::Zilla::Plugin::ReadmeAnyFromPod>
instead of L<[Readme]|Dist::Zilla::Plugin::Readme>.

=item *

Uses L<[RunExtraTests]|Dist::Zilla::Plugin::RunExtraTests> instead of
L<[ExtraTests]|Dist::Zilla::Plugin::ExtraTests>.

=item *

Includes the following additional plugins:
L<[MetaJSON]|Dist::Zilla::Plugin::MetaJSON>,
L<[PodSyntaxTests]|Dist::Zilla::Plugin::PodSyntaxTests>,
L<[Test::ReportPrereqs]|Dist::Zilla::Plugin::Test::ReportPrereqs>,
L<[Test::Compile]|Dist::Zilla::Plugin::Test::Compile>,
L<[Git::Check]|Dist::Zilla::Plugin::Git::Check>,
L<[Git::Commit]|Dist::Zilla::Plugin::Git::Commit>,
L<[Git::Tag]|Dist::Zilla::Plugin::Git::Tag>,
L<[Git::Push]|Dist::Zilla::Plugin::Git::Push>,
L<[MetaConfig]|Dist::Zilla::Plugin::MetaConfig>,
L<[MetaNoIndex]|Dist::Zilla::Plugin::MetaNoIndex>,
L<[MetaProvides::Package]|Dist::Zilla::Plugin::MetaProvides::Package>.

=back

=head1 BUGS

Report any issues on the public bugtracker.

=head1 AUTHOR

Dan Book <dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Dan Book.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=head1 SEE ALSO

L<Dist::Zilla>, L<Dist::Zilla::PluginBundle::Starter>, L<Dist::Milla>,
L<Dist::Zilla::MintingProfile::Starter::Git>
