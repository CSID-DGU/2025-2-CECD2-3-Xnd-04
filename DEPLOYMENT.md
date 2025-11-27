# Docker + AWS EC2 배포 가이드

이 가이드는 Xnd 애플리케이션을 Docker와 AWS EC2를 사용하여 배포하는 방법을 설명합니다.

> **전제 조건**: Git, Docker, Docker Compose가 설치되어 있고, `.env` 파일이 설정되어 있다고 가정합니다.

## 목차
1. [AWS EC2 인스턴스 설정](#aws-ec2-인스턴스-설정)
2. [애플리케이션 배포](#애플리케이션-배포)
3. [SSL 인증서 설정](#ssl-인증서-설정)
4. [Flutter 앱 설정](#flutter-앱-설정)
5. [모니터링 및 유지보수](#모니터링-및-유지보수)

---

## AWS EC2 인스턴스 설정

### 1. EC2 인스턴스 생성

1. **AWS Console 접속**
   - EC2 대시보드로 이동
   - "인스턴스 시작" 클릭

2. **인스턴스 설정**
   - **AMI**: Ubuntu Server 22.04 LTS
   - **인스턴스 타입**: t2.medium 이상 권장
   - **스토리지**: 30GB 이상 (gp3)
   - **보안 그룹 설정**:
     ```
     SSH (22): 내 IP
     HTTP (80): 0.0.0.0/0
     HTTPS (443): 0.0.0.0/0
     ```

3. **키 페어 생성 및 다운로드**
   - 새 키 페어 생성 (예: xnd-key.pem)
   - 안전한 위치에 저장

4. **탄력적 IP 할당** (권장)
   - EC2 대시보드 → 탄력적 IP → 새 주소 할당 → 인스턴스에 연결

### 2. 인스턴스 접속

```bash
# Windows (Git Bash 또는 PowerShell)
ssh -i "xnd-key.pem" ubuntu@your-ec2-public-ip

# 키 권한 오류 시 (Linux/Mac)
chmod 400 xnd-key.pem
```

---

## 애플리케이션 배포

### 1. Docker Compose로 실행

```bash
# 프로젝트 디렉토리로 이동
cd "Capstone Design"

# 컨테이너 빌드 및 시작 (백그라운드)
docker compose up -d --build

# 로그 확인
docker compose logs -f

# 특정 서비스 로그만 확인
docker compose logs -f backend
```

### 2. 초기 데이터베이스 설정

```bash
# 마이그레이션 실행
docker compose exec backend python manage.py migrate

# 슈퍼유저 생성
docker compose exec backend python manage.py createsuperuser

# Static 파일 수집
docker compose exec backend python manage.py collectstatic --noinput

# 초기 데이터 임포트 (선택사항)
docker compose exec backend python recipe_import.py
```

### 3. 배포 확인

```bash
# 컨테이너 상태 확인
docker compose ps

# 모든 컨테이너가 "Up" 상태여야 함
# 브라우저에서 http://your-ec2-ip 접속하여 확인
```

---

## SSL 인증서 설정 (Let's Encrypt)

### 1. 도메인 DNS 설정

- 도메인 등록 업체에서 A 레코드 추가
  - 호스트: @ (또는 www)
  - 값: EC2 탄력적 IP

### 2. Certbot 설치

```bash
sudo apt install certbot python3-certbot-nginx -y
```

### 3. Nginx 설정 수정

```bash
nano ~/Capstone\ Design/nginx/conf.d/default.conf
```

`server_name _;`를 실제 도메인으로 변경:
```nginx
server_name your-domain.com www.your-domain.com;
```

### 4. SSL 인증서 발급

```bash
# Docker 컨테이너 재시작
docker compose restart nginx

# SSL 인증서 발급
sudo certbot --nginx -d your-domain.com -d www.your-domain.com

# 자동 갱신 설정 확인
sudo certbot renew --dry-run
```

### 5. docker-compose.yml 수정

nginx 볼륨에 추가:
```yaml
nginx:
  volumes:
    - /etc/letsencrypt:/etc/letsencrypt:ro
```

### 6. 재시작

```bash
docker compose down
docker compose up -d
```

---

## Flutter 앱 설정

### 1. API 엔드포인트 설정

`Frontend/.env` 파일 수정:
```env
API_BASE_URL=https://your-domain.com/api
# 또는 HTTP인 경우
# API_BASE_URL=http://your-ec2-ip/api
```

### 2. Android 빌드

```bash
cd Frontend
flutter pub get
flutter build apk --release
```

빌드 파일 위치: `build/app/outputs/flutter-apk/app-release.apk`

### 3. iOS 빌드 (Mac 필요)

```bash
cd Frontend
flutter build ios --release
open ios/Runner.xcworkspace
```

---

## 모니터링 및 유지보수

### 로그 확인

```bash
# 전체 로그
docker compose logs -f

# 특정 서비스 로그
docker compose logs -f backend

# 마지막 100줄만 확인
docker compose logs --tail=100 backend
```

### 컨테이너 관리

```bash
# 컨테이너 재시작
docker compose restart

# 컨테이너 중지
docker compose stop

# 컨테이너 제거 (데이터는 유지)
docker compose down

# 컨테이너 및 볼륨 제거 (데이터 삭제 주의!)
docker compose down -v
```

### 코드 업데이트

```bash
cd ~/Capstone\ Design
git pull origin main
docker compose up -d --build
docker compose exec backend python manage.py migrate
```

### 데이터베이스 백업

```bash
# 백업
docker compose exec db mysqldump -u root -p${DB_ROOT_PASSWORD} ${DB_NAME} > backup_$(date +%Y%m%d).sql

# 복원
docker compose exec -T db mysql -u root -p${DB_ROOT_PASSWORD} ${DB_NAME} < backup.sql
```

### 리소스 모니터링

```bash
# 컨테이너 리소스 사용량
docker stats

# 디스크 사용량
df -h

# Docker 디스크 정리
docker system prune -a
```

---

## 트러블슈팅

### 메모리 부족 오류

```bash
# Swap 메모리 추가 (1GB)
sudo fallocate -l 1G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

### 포트 충돌

```bash
sudo netstat -tulpn | grep :80
sudo kill -9 <PID>
```

### 데이터베이스 연결 오류

```bash
docker compose logs db
docker compose exec db mysql -u root -p
```

### Celery 작동 안 함

```bash
docker compose logs celery_worker
docker compose exec redis redis-cli ping
```

---

## 유용한 명령어 모음

```bash
# Django 관리 명령 실행
docker compose exec backend python manage.py <command>

# Django shell 접속
docker compose exec backend python manage.py shell

# MySQL 접속
docker compose exec db mysql -u root -p

# Redis CLI 접속
docker compose exec redis redis-cli

# 컨테이너 내부 접속
docker compose exec backend bash
```

---

## 보안 체크리스트

- [ ] EC2 보안 그룹 최소 권한 원칙 적용
- [ ] SSH 접근 IP 제한
- [ ] 강력한 데이터베이스 비밀번호 사용
- [ ] DEBUG=False 설정
- [ ] ALLOWED_HOSTS 제한
- [ ] SSL/TLS 인증서 적용
- [ ] 정기적인 보안 업데이트
- [ ] 데이터베이스 정기 백업

---

작성자: Mhj
최종 수정일: 2025-11-23
