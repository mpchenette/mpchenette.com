use std::io::{Read, Write};
use std::net::{TcpListener, TcpStream};

fn main() {
    let port = std::env::var("PORT").unwrap_or_else(|_| "8000".to_string());
    let addr = format!("0.0.0.0:{}", port);

    let listener = TcpListener::bind(&addr).expect("Failed to bind to address");
    println!("Server running on {}", addr);

    for stream in listener.incoming() {
        match stream {
            Ok(stream) => {
                handle_connection(stream);
            }
            Err(e) => {
                eprintln!("Connection failed: {}", e);
            }
        }
    }
}

fn handle_connection(mut stream: TcpStream) {
    let mut buffer = [0; 1024];

    if let Err(e) = stream.read(&mut buffer) {
        eprintln!("Failed to read from stream: {}", e);
        return;
    }

    let response = "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n\r\nHello World";

    if let Err(e) = stream.write_all(response.as_bytes()) {
        eprintln!("Failed to write to stream: {}", e);
    }

    if let Err(e) = stream.flush() {
        eprintln!("Failed to flush stream: {}", e);
    }
}
