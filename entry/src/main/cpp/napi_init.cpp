#include "napi/native_api.h"
#include <algorithm>
#include <array>
#include <assert.h>
#include <bits/alltypes.h>
#include <cstdint>
#include <deque>
#include <fcntl.h>
#include <map>
#include <poll.h>
#include <pthread.h>
#include <pty.h>
#include <set>
#include <stdint.h>
#include <stdlib.h>
#include <string>
#include <sys/time.h>
#include <termios.h>
#include <unistd.h>
#include <vector>

#include "hilog/log.h"

#undef LOG_DOMAIN
#undef LOG_TAG
#define LOG_DOMAIN 0x3200
#define LOG_TAG "NapiTerminal"

struct Term {
    int fd;
    int pid;
    napi_threadsafe_function on_data_callback;
    napi_threadsafe_function on_exit_callback;
};

struct std::map<int, Term> terms;

struct data_buffer {
    char *buf;
    size_t size;
};

static void *terminal_worker(void *param) {

    int id = reinterpret_cast<intptr_t>(param);
    auto it = terms.find(id);
    assert(it != terms.end());

    auto *term = &it->second;

    int fd = term->fd;

    while (true) {

        struct pollfd fds[1];
        fds[0].fd = fd;
        fds[0].events = POLLIN;
        int res = poll(fds, 1, 100);

        uint8_t buffer[1024];
        if (res > 0) {
            ssize_t r = read(fd, buffer, sizeof(buffer) - 1);
            if (r > 0) {
                // pretty print
                std::string hex;
                for (int i = 0; i < r; i++) {
                    if (buffer[i] >= 127 || buffer[i] < 32) {
                        char temp[8];
                        snprintf(temp, sizeof(temp), "\\x%02x", buffer[i]);
                        hex += temp;
                    } else if (buffer[i] == '\'' || buffer[i] == '\"' || buffer[i] == '\\') {
                        char temp[8];
                        snprintf(temp, sizeof(temp), "\\%c", buffer[i]);
                        hex += temp;
                    } else {
                        hex += (char)buffer[i];
                    }
                }

                //  call callback registered by ArkTS
                if (hex.length() > 0 && term->on_data_callback != nullptr) {
                    data_buffer *pbuf = new data_buffer{.buf = new char[hex.length()], .size = (size_t)hex.length()};
                    memcpy(pbuf->buf, &hex[0], hex.length());
                    napi_call_threadsafe_function(term->on_data_callback, pbuf, napi_tsfn_nonblocking);
                }

                OH_LOG_INFO(LOG_APP, "Received, %{public}d, data: %{public}s", id, hex.c_str());
            } else if (r < 0) {

                OH_LOG_INFO(LOG_APP, "Program exited, id: %{public}d, %{public}ld %{public}d", id, r, errno);
                break;
            }
        }
    }

    if (term->on_exit_callback) {
        napi_call_threadsafe_function(term->on_exit_callback, nullptr, napi_tsfn_nonblocking);
    }

    if (term->on_data_callback) {
        napi_release_threadsafe_function(term->on_data_callback, napi_tsfn_release);
    }
    if (term->on_exit_callback) {
        napi_release_threadsafe_function(term->on_exit_callback, napi_tsfn_release);
    }
    terms.erase(id);

    return nullptr;
}

void call_on_data_callback(napi_env env, napi_value js_callback, void *context, void *data) {

    data_buffer *buffer = static_cast<data_buffer *>(data);

    napi_value ab;
    char *input;
    napi_create_arraybuffer(env, buffer->size, (void **)&input, &ab);
    memcpy(input, buffer->buf, buffer->size);

    napi_value global;
    napi_get_global(env, &global);

    napi_value result;
    napi_value args[1] = {ab};
    napi_call_function(env, global, js_callback, 1, args, &result);

    delete[] buffer->buf;
    delete buffer;
}

void call_on_exit_callback(napi_env env, napi_value js_callback, void *context, void *data) {

    napi_value global;
    napi_get_global(env, &global);

    napi_value result;
    napi_value args[1] = {};
    napi_call_function(env, global, js_callback, 0, args, &result);
}

static napi_value run(napi_env env, napi_callback_info info) {

    size_t argc = 5;
    napi_value args[5] = {nullptr};

    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    double value0;
    napi_get_value_double(env, args[0], &value0);
    double value1;
    napi_get_value_double(env, args[1], &value1);
    double value2;
    napi_get_value_double(env, args[2], &value2);

    int id = value0;
    int width = value1;
    int height = value2;

    struct winsize ws = {};
    ws.ws_col = width;
    ws.ws_row = height;

    // termios
    struct termios t {};
    struct termios *term = &t;

    term->c_iflag = ICRNL | IXON | IUTF8;
    term->c_oflag = NL0 | CR0 | TAB0 | BS0 | VT0 | FF0 | OPOST | ONLCR;
    term->c_cflag = B38400 | CS8 | CREAD;
    //  ICANON | ECHO removed
    term->c_lflag = ISIG | ECHOE | ECHOK | IEXTEN | ECHOCTL | ECHOKE;

    term->c_cc[VINTR] = 0x3;
    term->c_cc[VQUIT] = 0x1c;
    term->c_cc[VERASE] = 0x7f;
    term->c_cc[VKILL] = 0x15;
    term->c_cc[VEOF] = 0x4;
    term->c_cc[VMIN] = 0x1;
    term->c_cc[VSTART] = 0x11;
    term->c_cc[VSTOP] = 0x13;
    term->c_cc[VSUSP] = 0x1a;
    term->c_cc[VREPRINT] = 0x12;
    term->c_cc[VDISCARD] = 0xf;
    term->c_cc[VWERASE] = 0x17;
    term->c_cc[VLNEXT] = 0x16;

    term->c_cc[19] = 0x7f;
    term->c_cc[24] = 0x20;
    term->c_cc[25] = 0x88;
    term->c_cc[26] = 0xb6;
    term->c_cc[27] = 0x7f;
    term->c_cc[31] = 0x78;

    int fd;
    int pid = forkpty(&fd, nullptr, term, &ws);

    if (!pid) {
        const char *home = "/storage/Users/currentUser";
        setenv("HOME", home, 1);
        setenv("PWD", home, 1);
        setenv("PATH",
               "/data/app/bin:/data/service/hnp/bin:/bin:"
               "/usr/local/bin:/usr/bin:/system/bin:/vendor/bin",
               1);

        chdir(home);
        execl("/bin/sh", "/bin/sh", nullptr);
    }

    // set as non blocking
    int res = fcntl(fd, F_SETFL, fcntl(fd, F_GETFL) | O_NONBLOCK);
    assert(res == 0);
    
    auto te = Term{.fd = fd, .pid = pid};
    
    napi_value data_cb_name;
    napi_create_string_utf8(env, "data_callback", NAPI_AUTO_LENGTH, &data_cb_name);
    napi_create_threadsafe_function(env, args[3], nullptr, data_cb_name, 0, 1, nullptr, nullptr, nullptr,
                                    call_on_data_callback, &te.on_data_callback);

    napi_value exit_cb_name;
    napi_create_string_utf8(env, "exit_callback", NAPI_AUTO_LENGTH, &exit_cb_name);
    napi_create_threadsafe_function(env, args[4], nullptr, exit_cb_name, 0, 1, nullptr, nullptr, nullptr,
                                    call_on_exit_callback, &te.on_exit_callback);

    terms.emplace(id, te);

    // start terminal worker in another thread
    pthread_t terminal_thread;
    pthread_create(&terminal_thread, NULL, terminal_worker, (void *)(intptr_t)id);

    return nullptr;
}

// send data to terminal
static napi_value send(napi_env env, napi_callback_info info) {

    size_t argc = 2;
    napi_value args[2] = {nullptr};
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    double value0;
    napi_get_value_double(env, args[0], &value0);

    int id = value0;

    char *data;
    size_t length;
    napi_status ret = napi_get_arraybuffer_info(env, args[1], (void **)&data, &length);
    assert(ret == napi_ok);

    std::string hex;
    for (int i = 0; i < length; i++) {
        if (data[i] >= 127 || data[i] < 32) {
            char temp[8];
            snprintf(temp, sizeof(temp), "\\x%02x", data[i]);
            hex += temp;
        } else {
            hex += (char)data[i];
        }
    }
    OH_LOG_INFO(LOG_APP, "Send, id: %{public}d, data: %{public}s", id, hex.c_str());

    auto it = terms.find(id);

    if (it != terms.end()) {
        int fd = it->second.fd;
        int written = 0;
        while (written < length) {
            int size = write(fd, (uint8_t *)data + written, length - written);
            assert(size >= 0);
            written += size;
        }
    }

    return nullptr;
}

static napi_value resize(napi_env env, napi_callback_info info) {

    size_t argc = 3;
    napi_value args[3] = {nullptr};

    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    double value0;
    napi_get_value_double(env, args[0], &value0);
    double value1;
    napi_get_value_double(env, args[1], &value1);
    double value2;
    napi_get_value_double(env, args[2], &value2);

    int id = value0;
    auto it = terms.find(id);

    if (it != terms.end()) {

        int fd = it->second.fd;

        int width = value1;
        int height = value2;

        struct winsize ws = {};
        ws.ws_col = width;
        ws.ws_row = height;
        int ret = ioctl(fd, TIOCSWINSZ, &ws);
        assert(ret == 0);

        OH_LOG_INFO(LOG_APP, "Resize, id: %{public}d, (%{public}d, %{public}d)", id, width, height);
    }

    return nullptr;
}

static napi_value close(napi_env env, napi_callback_info info) {

    size_t argc = 1;
    napi_value args[1] = {nullptr};

    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    napi_valuetype valuetype0;
    napi_typeof(env, args[0], &valuetype0);
    double value0;
    napi_get_value_double(env, args[0], &value0);

    int id = (int)value0;

    auto iterm = terms.find(id);
    if (iterm != terms.end()) {
        
        OH_LOG_INFO(LOG_APP, "Close, id: %{public}d", id);
        
        kill(iterm->second.pid, 15);
    }

    return nullptr;
}

EXTERN_C_START
static napi_value Init(napi_env env, napi_value exports) {
    napi_property_descriptor desc[] = {
        {"run", nullptr, run, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"resize", nullptr, resize, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"send", nullptr, send, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"close", nullptr, close, nullptr, nullptr, nullptr, napi_default, nullptr}};
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    return exports;
}
EXTERN_C_END

static napi_module demoModule = {
    .nm_version = 1,
    .nm_flags = 0,
    .nm_filename = nullptr,
    .nm_register_func = Init,
    .nm_modname = "entry",
    .nm_priv = ((void *)0),
    .reserved = {0},
};

extern "C" __attribute__((constructor)) void RegisterEntryModule(void) { napi_module_register(&demoModule); }
