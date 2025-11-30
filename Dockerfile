FROM golang:alpine AS builder
WORKDIR /app
COPY go.mod main.go ./
RUN CGO_ENABLED=0 go build -ldflags="-s -w" -o hello-world .

FROM scratch
COPY --from=builder /app/hello-world .
ENV RUNTIME_ENV="Docker Container"
EXPOSE 8000
CMD ["./hello-world"]
