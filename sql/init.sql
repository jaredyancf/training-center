-- sql/init.sql
-- 教师表
CREATE TABLE IF NOT EXISTS teachers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    email VARCHAR(100),
    subject VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 学生表
CREATE TABLE IF NOT EXISTS students (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    email VARCHAR(100),
    grade VARCHAR(20),
    school VARCHAR(100),
    total_hours INT DEFAULT 0,
    remaining_hours INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 缴费记录表
CREATE TABLE IF NOT EXISTS payments (
    id SERIAL PRIMARY KEY,
    student_id INT REFERENCES students(id),
    amount DECIMAL(10,2) NOT NULL,
    hours_purchased INT NOT NULL,
    payment_method VARCHAR(50),
    payment_date DATE NOT NULL,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 课程安排表
CREATE TABLE IF NOT EXISTS schedules (
    id SERIAL PRIMARY KEY,
    student_id INT REFERENCES students(id),
    teacher_id INT REFERENCES teachers(id),
    course_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    subject VARCHAR(100),
    status VARCHAR(20) DEFAULT 'scheduled', -- scheduled, completed, cancelled
    hours_used INT DEFAULT 0,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 课时消耗记录
CREATE TABLE IF NOT EXISTS hour_logs (
    id SERIAL PRIMARY KEY,
    student_id INT REFERENCES students(id),
    schedule_id INT REFERENCES schedules(id),
    hours_used INT NOT NULL,
    type VARCHAR(20) NOT NULL, -- deduction, refund
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 插入测试数据
INSERT INTO teachers (name, phone, email, subject) VALUES
('张老师', '13800138001', 'zhang@example.com', '数学'),
('李老师', '13800138002', 'li@example.com', '英语'),
('王老师', '13800138003', 'wang@example.com', '物理');

INSERT INTO students (name, phone, email, grade, school, total_hours, remaining_hours) VALUES
('小明', '13900139001', 'xiaoming@example.com', '高一', '第一中学', 100, 80),
('小红', '13900139002', 'xiaohong@example.com', '高二', '第二中学', 120, 95),
('小李', '13900139003', 'xiaoli@example.com', '初三', '第三中学', 80, 60);