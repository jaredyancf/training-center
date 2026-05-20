# Dockerfile
FROM perl:5.36-slim

RUN apt-get update && \
    apt-get install -y \
    build-essential \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# 安装 cpanminus
RUN cpanm App::cpanminus

WORKDIR /app

# 复制 cpanfile 并安装依赖
COPY cpanfile .
RUN cpanm --installdeps --notest .

# 复制应用代码
COPY . .

EXPOSE 5000
CMD ["plackup", "-r", "-p", "5000", "app.psgi"]