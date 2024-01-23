package WorldOfAnime::Controller::DAO_Format;
use Moose;
use namespace::autoclean;
use Parse::BBCode;

BEGIN {extends 'Catalyst::Controller'; }


sub ParseBBCode :Local {
    my ( $text ) = @_;
    
    my $p = Parse::BBCode->new({
            tags => {
                # load the default tags
                Parse::BBCode::HTML->defaults,
                
                # add/override tags
                quote =>  '<div class="bbcode_quote_body"><div class="bbcode_quote_header"><img src="/static/images/icons/quote_icon.png"> %a originally said...</div>%s</div>',
            },
        }
    );
    
    my $rendered = $p->render($text);
    
    return $rendered;    
}



sub CleanBBCode :Local {
    my ( $text ) = @_;
    
    my $p = Parse::BBCode->new({
            tags => {
                quote =>  '',
            },
        }
    );
    
    my $rendered = $p->render($text);
    $rendered =~ s/<br([ \/])?>//g;
    #$rendered =~ s/\[(.*)\]//g;
    #$rendered =~ s/[QUOTE](.*)[\/QUOTE]//msg;
    #$rendered =~ s/[\/QUOTE]//g;
    
    return $rendered;    
}

__PACKAGE__->meta->make_immutable;

1;
