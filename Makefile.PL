use ExtUtils::MakeMaker;

WriteMakefile (
    NAME => 'Geo::Postcodes::JP',
    VERSION => '0.014',
    ABSTRACT => 'handle Japan Post Office postal code data',
    AUTHOR => 'Ben Bullock <bkb@cpan.org>',
    LICENSE => 'perl',
    PREREQ_PM => {
        # The ":all" is not defined in old versions so need recent
        # one.
        'Lingua::JA::Moji' => '0.11',
        # This is actually brought in by Lingua::JA::Moji anyway.
        'Convert::Moji' => 0,
        'DBI' => 0,
        'DBD::SQLite' => 0,
        'LWP::UserAgent' => 0,
    },
    META_MERGE => {
        resources => {
            repository => 'https://github.com/benkasminbullock/Geo-Postcodes-JP',
            homepage => 'http://prepan.org/module/3Yz7PYrBQM',
            bugtracker => 'https://github.com/benkasminbullock/Geo-Postcodes-JP/issues',
        },
        no_index => {
            directory => [
                'tmpl',
                'xt',
            ],
        }
    },
    # It seems to fail its tests on older Perls, so set minimum
    # version here. The problem is some kind of Unicode thing related
    # to the outputs of the SQLite queries.
    MIN_PERL_VERSION => '5.008009',
);

# Local variables:
# mode: perl
# End:

