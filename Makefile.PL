use ExtUtils::MakeMaker;

WriteMakefile (
    NAME => 'Geo::Postcodes::JP',
    VERSION => '0.002',
    ABSTRACT => 'handle the Japan Post Office postal code data',
    AUTHOR => 'Ben Bullock <bkb@cpan.org>',
    LICENSE => 'perl',
    PREREQ_PM => {
        'Lingua::JA::Moji' => 0,
        'Lingua::JA::FindDates' => 0,
        'DBI' => 0,
        'DBD::SQLite' => 0,
    },
    META_MERGE => {
        resources => {
            repository => 'https://github.com/benkasminbullock/Geo-Postcodes-JP',
            homepage => 'http://prepan.org/module/3Yz7PYrBQM',
            bugtracker => 'https://github.com/benkasminbullock/Geo-Postcodes-JP/issues',
        },
        no_index => {
            directory => [
                'tmpl' 
            ],
        }
    },
);

# Local variables:
# mode: perl
# End:

