# EC2 배포 가이드

EC2 인스턴스에서 Xnd 애플리케이션을 배포하는 방법입니다.

## 1. EC2 접속

```bash
ssh -i "xnd-key.pem" ubuntu@<EC2-퍼블릭-IP>
```

## 2. Docker 설치

```bash
# Docker 설치
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# 현재 사용자를 docker 그룹에 추가
sudo usermod -aG docker $USER
newgrp docker

# 설치 확인
docker --version
docker compose version
```

## 3. 저장소 클론

```bash
cd ~
git clone https://github.com/CSID-DGU/<저장소명>.git
cd "Capstone Design"
```

## 4. .env 파일 생성

```bash
nano .env
```

아래 내용을 붙여넣기:

```env
# Django Settings
SECRET_KEY=django-insecure-$@*dbvo&9ywvek6ru&%tar*tbp+ybc582$8y+^y^f@r6&f7%b&
DEBUG=False
ALLOWED_HOSTS=<EC2-퍼블릭-IP>,localhost,127.0.0.1

# Database Configuration
DB_NAME=xnddb
DB_USER=xnd_user
DB_PASSWORD=2022111993
DB_ROOT_PASSWORD=2022111993
DB_HOST=db
DB_PORT=3306

# Redis Configuration
REDIS_HOST=redis
REDIS_PORT=6379

# Celery Configuration
CELERY_BROKER_URL=redis://redis:6379/0
CELERY_RESULT_BACKEND=redis://redis:6379/0

# OAuth Configuration
KAKAO_CLIENT_ID=your-kakao-client-id
KAKAO_CLIENT_SECRET=your-kakao-client-secret

# JWT Configuration
JWT_SECRET_KEY=your-jwt-secret-key
JWT_ALGORITHM=HS256
JWT_EXPIRATION_HOURS=24
```

> `<EC2-퍼블릭-IP>`를 실제 EC2 IP로 변경하세요.

## 5. 빌드 및 실행

```bash
docker compose up -d --build
```

빌드에 약 20-30분 소요됩니다 (PyTorch, YOLO 등 대용량 패키지).

## 6. 빌드 로그 확인

```bash
docker compose logs -f
```

## 7. 초기 설정

```bash
# 마이그레이션
docker compose exec backend python manage.py migrate

# 슈퍼유저 생성
docker compose exec backend python manage.py shell -c "from XndApp.Models.user import User; u = User.objects.create_user('admin', 'local'); u.is_staff = True; u.is_superuser = True; u.set_password('password123'); u.save()"

# Static 파일 수집
docker compose exec backend python manage.py collectstatic --noinput
```

## 8. 컨테이너 상태 확인

```bash
docker compose ps
```

모든 컨테이너가 `Up` 상태여야 합니다.

## 9. 접속 확인

브라우저에서:
- Admin: `http://<EC2-퍼블릭-IP>/admin/`
- API: `http://<EC2-퍼블릭-IP>/api/`

로그인: `admin` / `password123`

## 트러블슈팅

### 메모리 부족 시

```bash
# Swap 메모리 추가
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

### 컨테이너 재시작

```bash
docker compose restart
```

### 로그 확인

```bash
docker compose logs backend --tail=50
```

### 전체 초기화

```bash
docker compose down -v
docker compose up -d --build
```
