# lib/TrainingCenter/Controller/Student.pm
package TrainingCenter::Controller::Student;

use strict;
use warnings;
use JSON;

sub new {
    my ($class, $db) = @_;
    return bless { db => $db }, $class;
}

sub list {
    my ($self, $req) = @_;
    
    my $sth = $self->{db}->prepare("SELECT * FROM students ORDER BY created_at DESC");
    $sth->execute();
    my @students;
    
    while (my $row = $sth->fetchrow_hashref) {
        push @students, $row;
    }
    
    return [200, ['Content-Type' => 'application/json'], [encode_json(\@students)]];
}

sub get {
    my ($self, $req, $id) = @_;
    
    my $sth = $self->{db}->prepare("SELECT * FROM students WHERE id = ?");
    $sth->execute($id);
    my $student = $sth->fetchrow_hashref;
    
    unless ($student) {
        return [404, ['Content-Type' => 'application/json'], [encode_json({error => 'Student not found'})]];
    }
    
    return [200, ['Content-Type' => 'application/json'], [encode_json($student)]];
}

sub create {
    my ($self, $req) = @_;
    
    my $body = decode_json($req->content);
    
    my $sth = $self->{db}->prepare(
        "INSERT INTO students (name, phone, email, grade, school) VALUES (?, ?, ?, ?, ?) RETURNING id"
    );
    $sth->execute(
        $body->{name},
        $body->{phone} || '',
        $body->{email} || '',
        $body->{grade} || '',
        $body->{school} || ''
    );
    
    my $row = $sth->fetchrow_hashref;
    
    return [201, ['Content-Type' => 'application/json'], [encode_json({id => $row->{id}, message => 'Student created'})]];
}

sub update {
    my ($self, $req, $id) = @_;
    
    my $body = decode_json($req->content);
    
    my $sth = $self->{db}->prepare(
        "UPDATE students SET name=?, phone=?, email=?, grade=?, school=? WHERE id=?"
    );
    $sth->execute(
        $body->{name},
        $body->{phone} || '',
        $body->{email} || '',
        $body->{grade} || '',
        $body->{school} || '',
        $id
    );
    
    return [200, ['Content-Type' => 'application/json'], [encode_json({message => 'Student updated'})]];
}

sub delete {
    my ($self, $req, $id) = @_;
    
    my $sth = $self->{db}->prepare("DELETE FROM students WHERE id = ?");
    $sth->execute($id);
    
    return [200, ['Content-Type' => 'application/json'], [encode_json({message => 'Student deleted'})]];
}

1;