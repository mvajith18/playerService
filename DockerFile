# Stage 1: Build the JAR file inside an Amazon Corretto Maven environment
FROM maven:3.9.6-amazoncorretto-21 AS builder
WORKDIR /app

# Cache dependencies to speed up subsequent local Jenkins builds
COPY pom.xml .
RUN mvn dependency:go-offline

# Copy source and compile the code
COPY src ./src
RUN mvn clean package -DskipTests

# Stage 2: Create a highly secure, minimal Amazon Corretto runtime image
FROM amazoncorretto:21-alpine
WORKDIR /app

# Create a non-root system user for security compliance
RUN addgroup -S spring && adduser -S spring -G spring
USER spring:spring

# Copy the compiled executable from the builder stage
COPY --from=builder /app/target/*.jar app.jar

EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]