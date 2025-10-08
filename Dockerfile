# ---------- Build stage ----------
FROM maven:3.9.9-eclipse-temurin-21 AS build
WORKDIR /app
COPY .mvn .mvn
COPY mvnw pom.xml ./
RUN chmod +x mvnw
# Descarga deps a cache
RUN ./mvnw -q -DskipTests dependency:go-offline
# Copiamos el resto y construimos
COPY src ./src
RUN ./mvnw -q -DskipTests clean package

# ---------- Runtime stage ----------
FROM eclipse-temurin:21-jre
ENV TZ=${TZ:-America/Mexico_City}
WORKDIR /opt/app
# Copiamos el fat jar
COPY --from=build /app/target/*SNAPSHOT.jar /opt/app/app.jar
EXPOSE 8080
# JVM flags suaves para contenedores
ENV JAVA_TOOL_OPTIONS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75"
ENTRYPOINT ["java","-jar","/opt/app/app.jar"]