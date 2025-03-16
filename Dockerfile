FROM golang:1.21-alpine

WORKDIR /app

# Install dependencies
RUN apk add --no-cache git

# Install goose
RUN go install github.com/pressly/goose/v3/cmd/goose@latest

# Create migrations directory
RUN mkdir -p /app/migrations

# Copy sample migration file
COPY ./migrations/ /app/migrations/

# Set working directory to migrations
WORKDIR /app/migrations

# Keep container running
CMD ["tail", "-f", "/dev/null"]
