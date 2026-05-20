## plack(perl) + postgres +docker  写的一个教培机构的学员管理系统

## 功能含有:  学生的缴费管理, 排课管理,  学生的课时管理,  教师管理



### 项目目录:

```
training-center/
├── docker-compose.yml
├── Dockerfile
├── cpanfile
├── app.psgi
├── lib/
│   └── TrainingCenter/
│       ├── DB.pm
│       └── Controller/
│           ├── Student.pm
│           ├── Payment.pm
│           ├── Course.pm
│           ├── Schedule.pm
│           └── Teacher.pm
├── sql/
│   └── init.sql
└── templates/
    └── index.html
```



### 使用说明:

```
# 1. 创建项目目录
mkdir training-center
cd training-center
mkdir -p lib/TrainingCenter/Controller sql templates

# 2. 将上述代码分别保存到对应文件

# 3. 启动服务
docker-compose up -d

# 4. 访问系统
# http://localhost:5000
```



### API 接口说明

#### 学生管理

- `GET /api/students` - 获取学生列表

- `GET /api/students/{id}` - 获取单个学生

- `POST /api/students` - 添加学生

- `PUT /api/students/{id}` - 更新学生

- `DELETE /api/students/{id}` - 删除学生

#### 教师管理

- `GET /api/teachers` - 获取教师列表（含统计数据）

- `GET /api/teachers/{id}` - 获取教师详情（含课表）

- `POST /api/teachers` - 添加教师

- `PUT /api/teachers/{id}` - 更新教师

- `DELETE /api/teachers/{id}` - 删除教师

#### 排课管理

- `GET /api/schedules` - 获取课程列表

- `POST /api/schedules` - 安排新课

- `PUT /api/schedules/{id}/complete` - 完成课程（自动扣课时）

- `PUT /api/schedules/{id}/cancel` - 取消课程

#### 缴费管理

- `GET /api/payments` - 获取缴费记录

- `POST /api/payments` - 记录缴费（自动增加课时）



### 示例请求

```
# 添加学生
curl -X POST http://localhost:5000/api/students \
  -H "Content-Type: application/json" \
  -d '{"name":"张三","grade":"高一","school":"第一中学"}'

# 记录缴费
curl -X POST http://localhost:5000/api/payments \
  -H "Content-Type: application/json" \
  -d '{"student_id":1,"amount":5000,"hours_purchased":50,"payment_date":"2025-01-15"}'

# 安排课程
curl -X POST http://localhost:5000/api/schedules \
  -H "Content-Type: application/json" \
  -d '{"student_id":1,"teacher_id":1,"course_date":"2025-01-20","start_time":"14:00","end_time":"15:30"}'
```





emai:   yan.yan.rf@gmail.com
