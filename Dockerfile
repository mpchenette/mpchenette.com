FROM rust:alpine AS builder
WORKDIR /app
COPY . .
RUN cargo build --release

FROM scratch
COPY --from=builder /app/target/release/hello-world .
ENV RUNTIME_ENV="Docker Container"
EXPOSE 8000
CMD ["./hello-world"]
