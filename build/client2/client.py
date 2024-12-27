import socket
import time

def start_client():
    while True:
        try:
            client_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            client_socket.connect(('echo-server2', 54322))
            client_socket.sendall(b'Hello world')
            data = client_socket.recv(1024)
            print(f"Received {data} from server")
            client_socket.close()
        except ConnectionRefusedError:
            print("Server is not available, retrying in 2 seconds...")
        except (ConnectionResetError, BrokenPipeError):
            print("Connection was reset, retrying in 2 seconds...")
        time.sleep(2)

if __name__ == "__main__":
    start_client()
