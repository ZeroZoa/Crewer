<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/6cb57774-776a-42ab-9441-493f6becef53" />




## 프로젝트 목표 및 상세 설명입니다!


러닝으로 이어지는 우리 Crewer입니다.<br></br>
Crewer은 러너들을 위한 커뮤니티이자 운동 기록 저장소입니다.<br></br>
위치 기반으로 함께 달릴 Crew를 모집하고, 소통하고, 기록하고, 랭킹시스템으로 비교하는 커뮤니티 서비스입니다.<br></br>

<br></br>



## 안녕하세요! Crewer 개발진들 입니다!


| [노승준](https://github.com/ZeroZoa) | [박근하](https://github.com/rmsgk1381) | [조근희](https://github.com/GeunheeCho) |
| :---: | :---: | :---: |
| <img width="150" height="150" alt="image" src="https://github.com/user-attachments/assets/d7ee5c78-4d33-4f3f-8475-578a42c18fbe" />| <img width="150" height="150" alt="image" src="https://github.com/user-attachments/assets/2ac71a7c-3441-4db2-892d-596827d57b85" /> | <img width="150" height="150" alt="image" src="https://github.com/user-attachments/assets/1e4b92b6-cd18-413d-88c3-391f4cd79b38" />| 
| 팀장(PM), Full Stack | Full Stack | Full Stack |


<br></br>

## 저희가 이용한 개발 언어 및 활용 기술, 도구들 입니다!

<br></br>

<div align="center">
  <img src="https://img.shields.io/badge/Java-000000?style=flat-square&logo=Java&logoColor=white"/>&nbsp;
  <img src="https://img.shields.io/badge/Spring-000000?style=flat-square&logo=Spring&logoColor=white"/>&nbsp;
  <img src="https://img.shields.io/badge/Spring JPA-000000?style=flat-square&logo=Spring-JPA&logoColor=white"/>&nbsp;
  <img src="https://img.shields.io/badge/Spring Security-000000?style=flat-square&logo=springsecurity&logoColor=white"/>&nbsp;
</div>

<div align="center">
  <img src="https://img.shields.io/badge/Dart-000000?style=flat-square&logo=Dart&logoColor=white"/>&nbsp;
  <img src="https://img.shields.io/badge/flutter-000000?style=flat-square&logo=flutter&logoColor=white"/>&nbsp;
  <img src="https://img.shields.io/badge/postgresql-000000?style=flat-square&logo=postgresql&logoColor=white"/>&nbsp;
  <img src="https://img.shields.io/badge/redis-000000?style=flat-square&logo=redis&logoColor=white"/>&nbsp;
  <img src="https://img.shields.io/badge/Docker-000000?style=flat-square&logo=Docker&logoColor=white"/>&nbsp;
</div>&nbsp&nbsp

<div align="center">
  <img src="https://img.shields.io/badge/macos-707070?style=flat-square&logo=macos&logoColor=white"/>&nbsp;
  <img src="https://img.shields.io/badge/intellijidea-707070?style=flat-square&logo=intellijidea&logoColor=white"/>&nbsp;
  <img src="https://img.shields.io/badge/github-707070?style=flat-square&logo=github&logoColor=white"/>&nbsp;
  <img src="https://img.shields.io/badge/notion-707070?style=flat-square&logo=notion&logoColor=white"/>&nbsp;
</div>

<br></br>

## 실행 방법

### 1. 환경 변수 설정
```bash
cp .env.example .env
# .env 파일을 열어 DB, JWT, Google Maps 등 실제 값 채우기
```

### 2. 백엔드 + 인프라 전체 실행 (Docker)
```bash
docker-compose up --build
```
`db`(PostgreSQL), `redis`, `rabbitmq`, `app`(Spring Boot) 컨테이너가 함께 뜨며, 백엔드는 `http://localhost:8080`에서 서비스됩니다.

### 3. 프론트엔드 실행 (Flutter)
```bash
cd frontend
flutter pub get
flutter run -d chrome
```

> IntelliJ에서 백엔드만 별도로 디버깅하려면, `docker-compose up -d db rabbitmq redis`로 인프라만 띄운 뒤 Run Configuration의 Active profiles에 `local`을 지정해 실행하세요. (`.env`는 EnvFile 플러그인으로 불러오는 것을 권장합니다.)

<br></br>


