# syntax=docker/dockerfile:1.6
FROM maven:3.9.9-eclipse-temurin-17 AS build

# Configuration Maven pour optimiser le build
ENV MAVEN_OPTS="-Dmaven.repo.local=/root/.m2/repository -Dmaven.artifact.threads=10"

WORKDIR /workspace

# Copie des fichiers de configuration Maven d'abord pour optimiser le cache des couches
COPY ../../../musafirgo-itinerary-service/pom.xml .
COPY ../../../musafirgo-itinerary-service/.mvn ./.mvn
COPY ../../../musafirgo-itinerary-service/mvnw ./
COPY ../../../musafirgo-itinerary-service/mvnw.cmd ./

# Téléchargement des dépendances (optimisation du cache Docker)
RUN --mount=type=cache,target=/root/.m2 mvn -B dependency:go-offline

# Copie du code source
COPY ../../../musafirgo-itinerary-service/src ./src

# Build de l'application
RUN --mount=type=cache,target=/root/.m2 mvn -B -DskipTests clean package

# Stage de production avec image distroless sécurisée
FROM gcr.io/distroless/java17-debian12:nonroot

# Métadonnées de l'image
LABEL maintainer="MusafirGo Team"
LABEL description="Service de gestion des itinéraires MusafirGo"
LABEL version="0.0.1-SNAPSHOT"

WORKDIR /app

# Copie du JAR depuis le stage de build
COPY --from=build /workspace/target/*.jar app.jar

# Utilisateur non-root pour la sécurité
USER nonroot:nonroot

# Exposition du port
EXPOSE 8080

# Configuration JVM pour la production
ENV JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -XX:+UseG1GC -XX:+UseStringDeduplication"

# Point d'entrée avec options JVM
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
