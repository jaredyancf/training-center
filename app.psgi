# app.psgi
use strict;
use warnings;
use lib 'lib';

use Plack::Builder;
use Plack::Request;
use Router::Simple;
use JSON;

use TrainingCenter::DB;
use TrainingCenter::Controller::Student;
use TrainingCenter::Controller::Payment;
use TrainingCenter::Controller::Schedule;
use TrainingCenter::Controller::Teacher;

# 连接数据库
my $dbh = TrainingCenter::DB->connect();

# 初始化控制器
my $student_controller = TrainingCenter::Controller::Student->new($dbh);
my $payment_controller = TrainingCenter::Controller::Payment->new($dbh);
my $schedule_controller = TrainingCenter::Controller::Schedule->new($dbh);
my $teacher_controller = TrainingCenter::Controller::Teacher->new($dbh);

# 创建路由
my $router = Router::Simple->new();

# 学生路由
$router->connect('/', {action => 'index'});
$router->connect('/api/students', {controller => $student_controller, action => 'list'});
$router->connect('/api/students/{id}', {controller => $student_controller, action => 'get'});

# 支付路由
$router->connect('/api/payments', {controller => $payment_controller, action => 'list'});

# 课程路由
$router->connect('/api/schedules', {controller => $schedule_controller, action => 'list'});

# 教师路由
$router->connect('/api/teachers', {controller => $teacher_controller, action => 'list'});
$router->connect('/api/teachers/{id}', {controller => $teacher_controller, action => 'get'});

my $app = sub {
    my $env = shift;
    my $req = Plack::Request->new($env);
    
    # 处理CORS
    if ($req->method eq 'OPTIONS') {
        return [
            200,
            [
                'Access-Control-Allow-Origin' => '*',
                'Access-Control-Allow-Methods' => 'GET, POST, PUT, DELETE, OPTIONS',
                'Access-Control-Allow-Headers' => 'Content-Type',
                'Content-Type' => 'application/json'
            ],
            ['{"status":"ok"}']
        ];
    }
    
    # 路由匹配
    my $path = $req->path_info;
    if (my $match = $router->match($env)) {
        my $controller = $match->{controller};
        my $action = $match->{action};
        my $id = $match->{id};
        
        # 首页
        if ($action eq 'index') {
            my $html = get_index_html();
            return [200, ['Content-Type' => 'text/html; charset=utf-8'], [$html]];
        }
        
        # 根据请求方法调用不同的action
        if ($req->method eq 'GET' && $action eq 'list') {
            return $controller->list($req);
        } elsif ($req->method eq 'GET' && $id) {
            return $controller->get($req, $id);
        } elsif ($req->method eq 'POST') {
            return $controller->create($req);
        } elsif ($req->method eq 'PUT' && $id) {
            return $controller->update($req, $id);
        } elsif ($req->method eq 'DELETE' && $id) {
            return $controller->delete($req, $id);
        }
        
        # 处理特殊的动作
        if ($req->method eq 'PUT' && $id && $req->path_info =~ /\/complete$/) {
            return $controller->complete($req, $id);
        }
        if ($req->method eq 'PUT' && $id && $req->path_info =~ /\/cancel$/) {
            return $controller->cancel($req, $id);
        }
    }
    
    # 处理没有匹配路由的动态请求
    if ($req->method eq 'POST' && $req->path_info eq '/api/students') {
        return $student_controller->create($req);
    } elsif ($req->method eq 'PUT' && $req->path_info =~ /^\/api\/students\/(\d+)$/) {
        return $student_controller->update($req, $1);
    } elsif ($req->method eq 'DELETE' && $req->path_info =~ /^\/api\/students\/(\d+)$/) {
        return $student_controller->delete($req, $1);
    } elsif ($req->method eq 'POST' && $req->path_info eq '/api/payments') {
        return $payment_controller->create($req);
    } elsif ($req->method eq 'POST' && $req->path_info eq '/api/schedules') {
        return $schedule_controller->create($req);
    } elsif ($req->method eq 'PUT' && $req->path_info =~ /^\/api\/schedules\/(\d+)\/complete$/) {
        return $schedule_controller->complete($req, $1);
    } elsif ($req->method eq 'PUT' && $req->path_info =~ /^\/api\/schedules\/(\d+)\/cancel$/) {
        return $schedule_controller->cancel($req, $1);
    } elsif ($req->method eq 'POST' && $req->path_info eq '/api/teachers') {
        return $teacher_controller->create($req);
    } elsif ($req->method eq 'PUT' && $req->path_info =~ /^\/api\/teachers\/(\d+)$/) {
        return $teacher_controller->update($req, $1);
    } elsif ($req->method eq 'DELETE' && $req->path_info =~ /^\/api\/teachers\/(\d+)$/) {
        return $teacher_controller->delete($req, $1);
    }
    
    # 404处理
    return [404, ['Content-Type' => 'application/json'], ['{"error":"Not found"}']];
};

# 首页HTML
sub get_index_html {
    return <<'HTML';
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>教培机构学员管理系统</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: Arial, sans-serif; background: #f0f2f5; }
        .container { max-width: 1200px; margin: 0 auto; padding: 20px; }
        h1 { text-align: center; color: #333; margin: 20px 0; }
        .tabs { display: flex; background: white; border-radius: 8px; margin-bottom: 20px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .tab { flex: 1; padding: 15px; text-align: center; cursor: pointer; border-bottom: 3px solid transparent; transition: all 0.3s; }
        .tab:hover { background: #f8f9fa; }
        .tab.active { border-bottom-color: #007bff; color: #007bff; font-weight: bold; }
        .content { background: white; border-radius: 8px; padding: 20px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .btn { padding: 10px 20px; background: #007bff; color: white; border: none; border-radius: 4px; cursor: pointer; margin: 5px; }
        .btn:hover { background: #0056b3; }
        .btn-danger { background: #dc3545; }
        .btn-success { background: #28a745; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th, td { padding: 12px; text-align: left; border-bottom: 1px solid #dee2e6; }
        th { background: #f8f9fa; font-weight: bold; }
        tr:hover { background: #f8f9fa; }
        .modal { display: none; position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0,0,0,0.5); }
        .modal-content { background: white; margin: 50px auto; padding: 20px; border-radius: 8px; max-width: 500px; }
        input, select { width: 100%; padding: 8px; margin: 8px 0; border: 1px solid #ddd; border-radius: 4px; }
        .form-group { margin-bottom: 15px; }
        label { font-weight: bold; margin-bottom: 5px; display: block; }
    </style>
</head>
<body>
    <div class="container">
        <h1>教培机构学员管理系统</h1>
        
        <div class="tabs">
            <div class="tab active" onclick="switchTab('students')">学生管理</div>
            <div class="tab" onclick="switchTab('teachers')">教师管理</div>
            <div class="tab" onclick="switchTab('schedules')">排课管理</div>
            <div class="tab" onclick="switchTab('payments')">缴费管理</div>
        </div>
        
        <div id="students" class="content">
            <button class="btn" onclick="showStudentModal()">添加学生</button>
            <div id="studentsTable"></div>
        </div>
        
        <div id="teachers" class="content" style="display:none;">
            <button class="btn" onclick="showTeacherModal()">添加教师</button>
            <div id="teachersTable"></div>
        </div>
        
        <div id="schedules" class="content" style="display:none;">
            <button class="btn" onclick="showScheduleModal()">安排课程</button>
            <div id="schedulesTable"></div>
        </div>
        
        <div id="payments" class="content" style="display:none;">
            <button class="btn" onclick="showPaymentModal()">记录缴费</button>
            <div id="paymentsTable"></div>
        </div>
    </div>
    
    <script>
        // 页面切换和数据加载逻辑
        function switchTab(tab) {
            document.querySelectorAll('.content').forEach(el => el.style.display = 'none');
            document.querySelectorAll('.tab').forEach(el => el.classList.remove('active'));
            document.getElementById(tab).style.display = 'block';
            document.querySelector(`[onclick="switchTab('${tab}')"]`).classList.add('active');
            loadData(tab);
        }
        
        function loadData(type) {
            switch(type) {
                case 'students': loadStudents(); break;
                case 'teachers': loadTeachers(); break;
                case 'schedules': loadSchedules(); break;
                case 'payments': loadPayments(); break;
            }
        }
        
        async function loadStudents() {
            const response = await fetch('/api/students');
            const students = await response.json();
            let html = '<table><tr><th>ID</th><th>姓名</th><th>年级</th><th>总课时</th><th>剩余课时</th><th>操作</th></tr>';
            students.forEach(s => {
                html += `<tr>
                    <td>${s.id}</td>
                    <td>${s.name}</td>
                    <td>${s.grade}</td>
                    <td>${s.total_hours}</td>
                    <td>${s.remaining_hours}</td>
                    <td>
                        <button class="btn" onclick="viewStudent(${s.id})">查看</button>
                        <button class="btn btn-danger" onclick="deleteStudent(${s.id})">删除</button>
                    </td>
                </tr>`;
            });
            html += '</table>';
            document.getElementById('studentsTable').innerHTML = html;
        }
        
        async function loadTeachers() {
            const response = await fetch('/api/teachers');
            const teachers = await response.json();
            let html = '<table><tr><th>ID</th><th>姓名</th><th>科目</th><th>总课程数</th><th>已完成</th><th>总课时</th><th>操作</th></tr>';
            teachers.forEach(t => {
                html += `<tr>
                    <td>${t.id}</td>
                    <td>${t.name}</td>
                    <td>${t.subject}</td>
                    <td>${t.stats.total_courses}</td>
                    <td>${t.stats.completed_courses}</td>
                    <td>${t.stats.total_hours_used}</td>
                    <td>
                        <button class="btn" onclick="viewTeacher(${t.id})">课表</button>
                        <button class="btn btn-danger" onclick="deleteTeacher(${t.id})">删除</button>
                    </td>
                </tr>`;
            });
            html += '</table>';
            document.getElementById('teachersTable').innerHTML = html;
        }
        
        async function loadSchedules() {
            const response = await fetch('/api/schedules');
            const schedules = await response.json();
            let html = '<table><tr><th>ID</th><th>学生</th><th>教师</th><th>日期</th><th>时间</th><th>状态</th><th>操作</th></tr>';
            schedules.forEach(s => {
                html += `<tr>
                    <td>${s.id}</td>
                    <td>${s.student_name}</td>
                    <td>${s.teacher_name}</td>
                    <td>${s.course_date}</td>
                    <td>${s.start_time}-${s.end_time}</td>
                    <td>${s.status}</td>
                    <td>
                        ${s.status === 'scheduled' ? 
                            `<button class="btn btn-success" onclick="completeCourse(${s.id})">完成</button>
                             <button class="btn btn-danger" onclick="cancelCourse(${s.id})">取消</button>` : ''}
                    </td>
                </tr>`;
            });
            html += '</table>';
            document.getElementById('schedulesTable').innerHTML = html;
        }
        
        async function loadPayments() {
            const response = await fetch('/api/payments');
            const payments = await response.json();
            let html = '<table><tr><th>ID</th><th>学生</th><th>金额</th><th>购买课时</th><th>日期</th></tr>';
            payments.forEach(p => {
                html += `<tr>
                    <td>${p.id}</td>
                    <td>${p.student_name}</td>
                    <td>¥${p.amount}</td>
                    <td>${p.hours_purchased}</td>
                    <td>${p.payment_date}</td>
                </tr>`;
            });
            html += '</table>';
            document.getElementById('paymentsTable').innerHTML = html;
        }
        
        // 模态框操作
        function showStudentModal() {
            alert('学生添加功能 - 请使用API接口');
        }
        
        function showTeacherModal() {
            alert('教师添加功能 - 请使用API接口');
        }
        
        // 初始化
        loadStudents();
    </script>
</body>
</html>
HTML
}

builder {
    
    $app;
};