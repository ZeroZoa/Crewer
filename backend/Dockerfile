# Dockerfile

# Gradle과 Java 21을 사용하여 Spring Boot 애플리케이션을 JAR 파일로 만듭니다.
FROM gradle:8.5.0-jdk21 AS build

# 작업 디렉토리를 /app으로 설정합니다.
WORKDIR /app

# 현재 프로젝트의 모든 파일(소스코드, gradle 설정 등)을 컨테이너 안으로 복사합니다.
COPY . .

# Gradle을 사용하여 프로젝트를 빌드하고 실행 가능한 JAR 파일을 생성합니다.
RUN gradle bootJar --no-daemon


# 실제 서비스를 실행할 최종 컨테이너 이미지를 만듭니다.
FROM eclipse-temurin:21-jre-jammy

# 작업 디렉토리를 /app으로 설정합니다.
WORKDIR /app

COPY --from=build /app/build/libs/*.jar app.jar

# 애플리케이션이 8080 포트를 사용한다고 외부에 알립니다.
EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]