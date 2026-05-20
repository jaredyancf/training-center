# lib/TrainingCenter/Controller/Teacher.pm
package TrainingCenter::Controller::Teacher;

use strict;
use warnings;
use JSON;

sub new {
    my ($class, $db) = @_;
    return bless { db => $db }, $class;
}

sub list {
    my ($self, $req) = @_;
    
    my $sth = $self->{db}->prepare("SELECT * FROM teachers ORDER BY created_at DESC");
    $sth->execute();
    my @teachers;
    
    while (my $row = $sth->fetchrow_hashref) {
        # 获取教师的课程统计
        my $stats = $self->{db}->prepare(
            "SELECT 
                COUNT(*) as total_courses,
                COUNT(CASE WHEN status='completed' THEN 1 END) as completed_courses,
                SUM(hours_used) as total_hours_used
             FROM schedules WHERE teacher_id = ?"
        );
        $stats->execute($row->{id});
        my $stat_row = $stats->fetchrow_hashref;
        
        $row->{stats} = {
            total_courses => $stat_row->{total_courses} || 0,
            completed_courses => $stat_row->{completed_courses} || 0,
            total_hours_used => $stat_row->{total_hours_used} || 0
        };
        
        push @teachers, $row;
    }
    
    return [200, ['Content-Type' => 'application/json'], [encode_json(\@teachers)]];
}

sub get {
    my ($self, $req, $id) = @_;
    
    my $sth = $self->{db}->prepare("SELECT * FROM teachers WHERE id = ?");
    $sth->execute($id);
    my $teacher = $sth->fetchrow_hashref;
    
    unless ($teacher) {
        return [404, ['Content-Type' => 'application/json'], [encode_json({error => 'Teacher not found'})]];
    }
    
    # 获取教师课表
    my $schedule = $self->{db}->prepare(
        "SELECT sch.*, s.name as student_name 
         FROM schedules sch 
         JOIN students s ON sch.student_id = s.id 
         WHERE sch.teacher_id = ? 
         ORDER BY sch.course_date, sch.start_time"
    );
    $schedule->execute($id);
    my @schedules;
    while (my $row = $schedule->fetchrow_hashref) {
        push @schedules, $row;
    }
    $teacher->{schedules} = \@schedules;
    
    return [200, ['Content-Type' => 'application/json'], [encode_json($teacher)]];
}

sub create {
    my ($self, $req) = @_;
    
    my $body = decode_json($req->content);
    
    my $sth = $self->{db}->prepare(
        "INSERT INTO teachers (name, phone, email, subject) VALUES (?, ?, ?, ?) RETURNING id"
    );
    $sth->execute(
        $body->{name},
        $body->{phone} || '',
        $body->{email} || '',
        $body->{subject} || ''
    );
    
    my $row = $sth->fetchrow_hashref;
    
    return [201, ['Content-Type' => 'application/json'], [encode_json({id => $row->{id}, message => 'Teacher created'})]];
}

sub update {
    my ($self, $req, $id) = @_;
    
    my $body = decode_json($req->content);
    
    my $sth = $self->{db}->prepare(
        "UPDATE teachers SET name=?, phone=?, email=?, subject=? WHERE id=?"
    );
    $sth->execute(
        $body->{name},
        $body->{phone} || '',
        $body->{email} || '',
        $body->{subject} || '',
        $id
    );
    
    return [200, ['Content-Type' => 'application/json'], [encode_json({message => 'Teacher updated'})]];
}

sub delete {
    my ($self, $req, $id) = @_;
    
    my $sth = $self->{db}->prepare("DELETE FROM teachers WHERE id = ?");
    $sth->execute($id);
    
    return [200, ['Content-Type' => 'application/json'], [encode_json({message => 'Teacher deleted'})]];
}

1;