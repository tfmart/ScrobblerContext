# Use the official Swift image
FROM swift:5.8 as builder

# Set the working directory
WORKDIR /app

# Copy the package files and resolve dependencies
COPY Package.swift Package.resolved ./
RUN swift package resolve

# Copy the rest of the source code
COPY . .

# Build the server
RUN swift build -c release

# Create a new image for the runtime
FROM swift:5.8-slim

# Set the working directory
WORKDIR /app

# Copy the built server from the builder image
COPY --from=builder /app/.build/release/YourMCPServerExecutable .

# Set environment variables (you can also pass them dynamically at runtime)
ENV LASTFM_API_KEY=${LASTFM_API_KEY}
ENV LASTFM_SECRET_KEY=${LASTFM_SECRET_KEY}

# Set the entrypoint to run the server
ENTRYPOINT ["./YourMCPServerExecutable"]
