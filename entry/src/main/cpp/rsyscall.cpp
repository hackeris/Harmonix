#include "rsyscall.h"
#include <asm/unistd.h>
#include <errno.h>
#include <fcntl.h>
#include <linux/limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <termios.h>
#include <unistd.h>

#include "hilog/log.h"

#undef LOG_DOMAIN
#undef LOG_TAG
#define LOG_DOMAIN 0x3200
#define LOG_TAG "NapiTerminal"

static void handle_client(int client_fd) {

    int call;

    ssize_t received;

    int len;
    char path[PATH_MAX];
    int operation;
    struct termios data;

    int fd;
    int r;

    if (recv(client_fd, &call, sizeof(int), 0) != sizeof(int)) {
        goto err;
    }

    if (call == __NR_ioctl) {

        if ((received = recv(client_fd, &len, sizeof(int), 0)) != sizeof(int)) {
            goto end;
        }

        if ((received = recv(client_fd, path, len, 0)) != len) {
            goto end;
        }
        path[len] = '\0';

        if ((received = recv(client_fd, &operation, sizeof(int), 0)) != sizeof(int)) {
            goto end;
        }

        if ((received = recv(client_fd, &data, sizeof(struct termios), 0)) != sizeof(struct termios)) {
            goto end;
        }

        fd = open(path, O_RDWR);
        if (fd < 0) {
            goto err;
        }
        received = ioctl(fd, operation, &data);
        if (received < 0) {
            goto err;
        }

        send(client_fd, &r, sizeof(r), 0);
    }

err: {
    int error = errno;
    send(client_fd, &error, sizeof(int), 0);
}
end:
    // Close sockets
    close(client_fd);
}

void *start_server(void *param) {

    const char *unix_socket_path = static_cast<char *>(param);

    int server_fd, client_fd;
    struct sockaddr_un server_addr, client_addr;
    socklen_t client_len;

    // Create socket
    server_fd = socket(AF_UNIX, SOCK_STREAM, 0);
    if (server_fd == -1) {
        OH_LOG_INFO(LOG_APP, "socket failed, %{public}d", errno);
        goto end;
    }

    // Remove existing socket file if it exists
    unlink(unix_socket_path);

    // Bind socket to a path
    memset(&server_addr, 0, sizeof(struct sockaddr_un));
    server_addr.sun_family = AF_UNIX;
    strncpy(server_addr.sun_path, unix_socket_path, sizeof(server_addr.sun_path) - 1);

    if (bind(server_fd, (struct sockaddr *)&server_addr, sizeof(struct sockaddr_un)) == -1) {
        OH_LOG_INFO(LOG_APP, "bind failed, %{public}d", errno);
        goto end;
    }

    // Listen for incoming connections
    if (listen(server_fd, 5) == -1) {
        OH_LOG_INFO(LOG_APP, "listen failed, %{public}d", errno);
        goto end;
    }

    while (1) {
        // Accept client connection
        client_len = sizeof(struct sockaddr_un);
        client_fd = accept(server_fd, (struct sockaddr *)&client_addr, &client_len);
        if (client_fd == -1) {
            break;
        }
        handle_client(client_fd);
    }

end:
    close(server_fd);
    unlink(unix_socket_path); // Clean up socket file

    return 0;
}
