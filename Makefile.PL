use ExtUtils::MakeMaker;
WriteMakefile (
    NAME => 'Agent',
    DISTNAME => 'Agent',
    VERSION => '2.91',
    'dist' => {COMPRESS=>'gzip',SUFFIX=>'gz'}
);
