FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
COPY app.jar app.jar
RUN addgroup -S mcart && adduser -S mcart -G mcart
USER mcart
EXPOSE 8081
ENTRYPOINT ["java", "-Xmx100m", "-Xms40m", "-XX:+UseG1GC", "-XX:MaxMetaspaceSize=80m", "-jar", "app.jar"]
