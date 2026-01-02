FROM openjdk:11-jre-slim
WORKDIR /app
COPY target/devops-demo-1.0.jar app.jar
CMD ["java", "-jar", "app.jar"]

