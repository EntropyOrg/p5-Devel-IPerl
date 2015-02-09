package Devel::IPerl::Display::JS;

use strict;
use warnings;

use Moo;
with qw(Devel::IPerl::Display::Role::Displayable Devel::IPerl::Display::Role::Source);

sub iperl_data_representations {
	my ($self) = @_;
	my $html;
	if( $self->uri ) {
		$html = <<"HTML";
 <script src="@{[$self->uri]}" type="text/javascript"></script>
HTML
	} elsif( $self->bytestream ) {
		$html = <<"HTML";
<script type="text/javascript">
@{[ $self->bytestream ]}
</script>
HTML
	}
	return {
		"text/html" => $html,
	};
}

1;
