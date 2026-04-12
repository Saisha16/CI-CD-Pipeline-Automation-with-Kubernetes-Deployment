FROM eclipse-temurin:17-jre
WORKDIR /app
COPY target/cicd-app-1.0.jar app.jar
ENV LOGSTASH_HOST=logstash
ENV LOGSTASH_PORT=5000
ENTRYPOINT ["java","-jar","app.jar"]