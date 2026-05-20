# lib/TrainingCenter/DB.pm
package TrainingCenter::DB;

use strict;
use warnings;
use DBI;

my $dbh;

sub connect {
    my $class = shift;
    
    unless ($dbh) {
        my $host = $ENV{DB_HOST} || 'localhost';
        my $name = $ENV{DB_NAME} || 'training_center';
        my $user = $ENV{DB_USER} || 'admin';
        my $pass = $ENV{DB_PASS} || 'secret';
        
        $dbh = DBI->connect(
            "dbi:Pg:dbname=$name;host=$host;port=5432",
            $user,
            $pass,
            {
                RaiseError => 1,
                AutoCommit => 1,
                pg_enable_utf8 => 1
            }
        );
    }
    
    return $dbh;
}

1;