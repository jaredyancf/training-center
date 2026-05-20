# lib/TrainingCenter/Controller/Payment.pm
package TrainingCenter::Controller::Payment;

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
    my $sql = "SELECT p.*, s.name as student_name FROM payments p 
               JOIN students s ON p.student_id = s.id";
    
    if ($student_id) {
        $sql .= " WHERE p.student_id = ?";
    }
    $sql .= " ORDER BY p.payment_date DESC";
    
    my $sth = $self->{db}->prepare($sql);
    
    if ($student_id) {
        $sth->execute($student_id);
    } else {
        $sth->execute();
    }
    
    my @payments;
    while (my $row = $sth->fetchrow_hashref) {
        push @payments, $row;
    }
    
    return [200, ['Content-Type' => 'application/json'], [encode_json(\@payments)]];
}

sub create {
    my ($self, $req) = @_;
    
    my $body = decode_json($req->content);
    $self->{db}->begin_work;
    
    eval {
        # 插入缴费记录
        my $sth = $self->{db}->prepare(
            "INSERT INTO payments (student_id, amount, hours_purchased, payment_method, payment_date, notes) 
             VALUES (?, ?, ?, ?, ?, ?) RETURNING id"
        );
        $sth->execute(
            $body->{student_id},
            $body->{amount},
            $body->{hours_purchased},
            $body->{payment_method} || '现金',
            $body->{payment_date},
            $body->{notes} || ''
        );
        
        # 更新学生课时
        my $update = $self->{db}->prepare(
            "UPDATE students SET total_hours = total_hours + ?, 
             remaining_hours = remaining_hours + ? WHERE id = ?"
        );
        $update->execute($body->{hours_purchased}, $body->{hours_purchased}, $body->{student_id});
        
        $self->{db}->commit;
    };
    
    if ($@) {
        $self->{db}->rollback;
        return [500, ['Content-Type' => 'application/json'], [encode_json({error => $@})]];
    }
    
    return [201, ['Content-Type' => 'application/json'], [encode_json({message => 'Payment recorded'})]];
}

1;