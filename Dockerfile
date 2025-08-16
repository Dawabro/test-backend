FROM swift:5.9-jammy as build

WORKDIR /build

# Copy entire project
COPY . .

# Build for release
RUN swift build -c release --static-swift-stdlib

# Switch to runtime image
FROM swift:5.9-jammy-slim

WORKDIR /app

# Copy build artifacts
COPY --from=build /build/.build/release/App /app

# Expose port
EXPOSE 8080

# Set entrypoint
ENTRYPOINT ["./App"]