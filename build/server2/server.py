import socket

def start_server():
    server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server_socket.bind(('0.0.0.0', 54322))
    server_socket.listen()

    while True:
        client_socket, addr = server_socket.accept()
        try:
            while True:
                data = client_socket.recv(1024)
                if not data:
                    break
                print(f"Received {data} from {addr}")
                client_socket.sendall(data)
        except ConnectionResetError:
            print("Client disconnected")
        finally:
            client_socket.close()

if __name__ == "__main__":
    start_server()
