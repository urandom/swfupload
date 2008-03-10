use Test::More tests => 5;
use IWL::SWFUpload;

BEGIN {use_ok('IWL::SWFUpload::Queue')}

{
    my $q = IWL::SWFUpload::Queue->new;
    ok(!$q->getContent);
    my $u = IWL::SWFUpload->new;
    $q = $q->new;
    ok(!$q->bindToUpload(IWL::Object->new));
    is($q->bindToUpload($u), $q);
    ok($q->getContent);
}
