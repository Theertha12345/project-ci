FROM eclipse-temurin:11-jre-jammy
WORKDIR /app
COPY target/devops-demo-1.0.jar app.jar
ENTRYPOINT ["java","-jar","app.jar"]

