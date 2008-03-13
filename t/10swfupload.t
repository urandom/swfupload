use Test::More tests => 19;

BEGIN {use_ok('IWL::SWFUpload')}

{
    my $swf = IWL::SWFUpload->new;
    ok(!$swf->getContent);
    my $swf2 = IWL::SWFUpload->new;
    $swf2->setUploadURL('foo.pl');
    ok($swf2->getContent);
}

{
    my $swf = IWL::SWFUpload->new;
    ok(!$swf->isMultiple);
    is($swf->setMultiple(1), $swf);
    ok($swf->isMultiple);
    is($swf->setUploadURL('foo.pl'), $swf);
    is($swf->getUploadURL, 'foo.pl');
    is($swf->setPostParams(foo => 'bar', alpha => 1), $swf);
    is_deeply({$swf->getPostParams}, {foo => 'bar', alpha => 1});
    is($swf->setFileTypes("*.jpg;*.gif", "Images"), $swf);
    is_deeply([$swf->getFileTypes], ["*.jpg;*.gif", "Images"]);
    is($swf->setFileSizeLimit(2500), $swf);
    is($swf->getFileSizeLimit, 2500);
    is($swf->setFileUploadLimit(5), $swf);
    is($swf->getFileUploadLimit, 5);
    is($swf->setFileQueueLimit(5), $swf);
    is($swf->getFileQueueLimit, 5);
    is($swf->registerPlugin('cookie'), $swf);
}
