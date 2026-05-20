# lib/TrainingCenter/Controller/Schedule.pm
package TrainingCenter::Controller::Schedule;

use strict;
use warnings;
use JSON;

sub new {
    my ($class, $db) = @_;
    return bless { db => $db }, $class;
}

sub list {
    my ($self, $req) = @_;
    
    my $student_id = $req->parameters->{student_id};
    my $teacher_id = $req->parameters->{teacher_id};
    my $date = $req->parameters->{date};
    
    my $sql = "SELECT sch.*, s.name as student_name, t.name as teacher_name 
               FROM schedules sch 
               JOIN students s ON sch.student_id = s.id 
               JOIN teachers t ON sch.teacher_id = t.id 
               WHERE 1=1";
    
    my @params;
    if ($student_id) {
        $sql .= " AND sch.student_id = ?";
        push @params, $student_id;
    }
    if ($teacher_id) {
        $sql .= " AND sch.teacher_id = ?";
        push @params, $teacher_id;
    }
    if ($date) {
        $sql .= " AND sch.course_date = ?";
        push @params, $date;
    }
    
    $sql .= " ORDER BY sch.course_date, sch.start_time";
    
    my $sth = $self->{db}->prepare($sql);
    $sth->execute(@params);
    
    my @schedules;
    while (my $row = $sth->fetchrow_hashref) {
        push @schedules, $row;
    }
    
    return [200, ['Content-Type' => 'application/json'], [encode_json(\@schedules)]];
}

sub create {
    my ($self, $req) = @_;
    
    my $body = decode_json($req->content);
    
    my $sth = $self->{db}->prepare(
        "INSERT INTO schedules (student_id, teacher_id, course_date, start_time, end_time, subject, notes) 
         VALUES (?, ?, ?, ?, ?, ?, ?) RETURNING id"
    );
    $sth->execute(
        $body->{student_id},
        $body->{teacher_id},
        $body->{course_date},
        $body->{start_time},
        $body->{end_time},
        $body->{subject} || '',
        $body->{notes} || ''
    );
    
    my $row = $sth->fetchrow_hashref;
    
    return [201, ['Content-Type' => 'application/json'], [encode_json({id => $row->{id}, message => 'Schedule created'})]];
}

sub complete {
    my ($self, $req, $id) = @_;
    
    my $body = decode_json($req->content);
    my $hours_used = $body->{hours_used} || 1;
    
    $self->{db}->begin_work;
    
    eval {
        # 更新课程状态
        my $sth = $self->{db}->prepare(
            "UPDATE schedules SET status='completed', hours_used=? WHERE id=? RETURNING student_id"
        );
        $sth->execute($hours_used, $id);
        my $row = $sth->fetchrow_hashref;
        
        # 扣减学生课时
        my $update = $self->{db}->prepare(
            "UPDATE students SET remaining_hours = remaining_hours - ? WHERE id = ?"
        );
        $update->execute($hours_used, $row->{student_id});
        
        # 记录课时消耗
        my $log = $self->{db}->prepare(
            "INSERT INTO hour_logs (student_id, schedule_id, hours_used, type, description) 
             VALUES (?, ?, ?, 'deduction', ?)"
        );
        $log->execute($row->{student_id}, $id, $hours_used, $body->{description} || '正常消耗');
        
        $self->{db}->commit;
    };
    
    if ($@) {
        $self->{db}->rollback;
        return [500, ['Content-Type' => 'application/json'], [encode_json({error => $@})]];
    }
    
    return [200, ['Content-Type' => 'application/json'], [encode_json({message => 'Course completed'})]];
}

sub cancel {
    my ($self, $req, $id) = @_;
    
    my $sth = $self->{db}->prepare(
        "UPDATE schedules SET status='cancelled' WHERE id=?"
    );
    $sth->execute($id);
    
    return [200, ['Content-Type' => 'application/json'], [encode_json({message => 'Schedule cancelled'})]];
}

1;