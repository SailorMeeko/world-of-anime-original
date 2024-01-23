package WorldOfAnime::Model::Formatter;
use HTML::TagFilter;
use Moose;

BEGIN { extends 'Catalyst::Model' }


has 'from' => (
  is => 'rw',
  isa => 'Str',
);

has 'to' => (
  is => 'rw',
  isa => 'Str',
);


sub prettify {
    my $self = shift;
    my $text = shift || $self->from;
    
    my (@chars) = qw/\` \~ \! \@ \# \$ \% \^ \* \( \) \- \_ \+ \= \| \\\ \? \, \. \[ \{ \] \} \< \> \/ \' \"/;
    
    foreach my $char (@chars) { $text =~ s/$char//g; }
    $text =~ s/\&/ and /g;
    $text =~ s/\s+/_/g;
    $text = lc($text);
    
    return $text;
}


# Expands our shorthand into full URLs
sub expand {
    my ( $self, $text ) = @_;
    
    # {p:user} => <a href="/profile/{user}">{user}</a>
    # {pw:user} => <a href="/profile/{user}">profile</a>
    
    $text =~ s/{p:(.*?)}/<a href="\/profile\/$1">$1<\/a>/g;
    $text =~ s/{pw:(.*?)}/<a href="\/profile\/$1">profile<\/a>/g;
    
    return $text;
}


sub clean_html {
    my ( $self, $html ) = @_;
    
    my $tf = new HTML::TagFilter;
    $tf->allow_tags( {font=>{'any'} } );    
    my $clean_html = $tf->filter($html);

    return $clean_html;
}



1;