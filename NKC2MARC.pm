package App::NKC2MARC;

use strict;
use warnings;

use Encode qw(encode_utf8);
use English;
use Error::Pure qw(err);
use Getopt::Std;
use IO::Barf qw(barf);
use ZOOM;

our $VERSION = 0.01;

$| = 1;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# Object.
	return $self;
}

# Run.
sub run {
	my $self = shift;

	# Process arguments.
	$self->{'_opts'} = {
		'h' => 0,
		'v' => 0,
		'u' => 0,
	};
	if (! getopts('huv', $self->{'_opts'}) || @ARGV < 1
		|| $self->{'_opts'}->{'h'}) {

		print STDERR "Usage: $0 [-h] [-u] [-v] [--version] id_of_book\n";
		print STDERR "\t-h\t\t\tPrint help.\n";
		print STDERR "\t-u\t\t\tUpload (instead of print).\n";
		print STDERR "\t-v\t\t\tVerbose mode.\n";
		print STDERR "\t--version\t\tPrint version.\n";
		print STDERR "\tid_of_book\t\tIdentifier of book e.g. Czech ".
			"national bibliography id or ISBN\n";
		return 1;
	}
	$self->{'_id_of_book'} = shift @ARGV;

	# Configuration of National library of the Czech Republic service.
	my $c = {
		host => 'aleph.nkp.cz',
		port => '9991',
		database => 'NKC01',
		record => 'usmarc'
	};

	# ZOOM object.
	my $conn = eval {
		ZOOM::Connection->new(
			$c->{'host'}, $c->{'port'},
			'databaseName' => $c->{'database'},
		);
	};
	if ($EVAL_ERROR) {
		err "Cannot connect to '".$c->{'host'}."'.",
			'Code', $EVAL_ERROR->code,
			'Message', $EVAL_ERROR->message,
		;
	}
	$conn->option(preferredRecordSyntax => $c->{'record'});

	# Get MARC record from library.
	my ($rs, $ccnb);
	## CCNB
	if ($self->{'_id_of_book'} =~ m/^cnb\d+$/ms) {
		$rs = $conn->search_pqf('@attr 1=48 '.$self->{'_id_of_book'});
		if (! defined $rs || ! $rs->size) {
			print STDERR encode_utf8("Edition with ČČNB '$self->{'_id_of_book'}' doesn't exist.\n");
			return 1;
		}
		$ccnb = $self->{'_id_of_book'};
	## ISBN
	} else {
		$rs = $conn->search_pqf('@attr 1=7 '.$self->{'_id_of_book'});
		if (! defined $rs || ! $rs->size) {
			print STDERR "Edition with ISBN '$self->{'_id_of_book'}' doesn't exist.\n";
			return 1;
		}
	}
	my $raw_record = $rs->record(0)->raw;
	barf($ccnb.'.mrc', $raw_record);

	return 0;
}

1;


__END__

=pod

=encoding utf8

=head1 NAME

App::NKC2MARC - Base class for nkc-to-marc script.

=head1 SYNOPSIS

 use App::NKC2MARC;

 my $app = App::NKC2MARC->new;
 my $exit_code = $app->run;

=head1 METHODS

=head2 C<new>

 my $app = App::NKC2MARC->new;

Constructor.

Returns instance of object.

=head2 C<run>

 my $exit_code = $app->run;

Run.

Returns 1 for error, 0 for success.

=head1 EXAMPLE

 use strict;
 use warnings;

 use App::NKC2MARC;

 # Arguments.
 @ARGV = (
         'Library',
 );

 # Run.
 exit App::NKC2MARC->new->run;

 # Output like:
 # TODO

=head1 DEPENDENCIES

L<Business::ISBN>,
L<Encode>,
L<Error::Pure>,
L<Getopt::Std>,
L<MARC::Convert::Wikidata>,
L<MARC::Record>,
L<ZOOM>,
L<WQS::SPARQL>,
L<WQS::SPARQL::Query::Count>,
L<WQS::SPARQL::Query::Select>,
L<WQS::SPARQL::Result>,
L<Wikibase::API>,
L<Wikibase::Cache>,
L<Wikibase::Datatype::Print::Item>.
L<Wikidata::Reconcilation::AudioBook>,
L<Wikidata::Reconcilation::BookSeries>,
L<Wikidata::Reconcilation::Periodical>,
L<Wikidata::Reconcilation::VersionEditionOrTranslation>

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/App-NKC2MARC>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2024 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.01

=cut
