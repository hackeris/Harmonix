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
#include <unistd.h>
#include <vector>

#include "hilog/log.h"

#undef LOG_DOMAIN
#undef LOG_TAG
#define LOG_DOMAIN 0x3200
#define LOG_TAG "NapiTerminal"

static int fd = -1;

static napi_value resize(napi_env env, napi_callback_info info) {

    size_t argc = 2;
    napi_value args[2] = {nullptr};

    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    napi_valuetype valuetype0;
    napi_typeof(env, args[0], &valuetype0);

    napi_valuetype valuetype1;
    napi_typeof(env, args[1], &valuetype1);

    double value0;
    napi_get_value_double(env, args[0], &value0);

    double value1;
    napi_get_value_double(env, args[1], &value1);

    int width = value0;
    int height = value1;

    if (fd > 0) {
        struct winsize ws = {};
        ws.ws_col = width;
        ws.ws_row = height;
        int ret = ioctl(fd, TIOCSWINSZ, &ws);
        assert(ret == 0);

        OH_LOG_INFO(LOG_APP, "Resize: %{public}d, %{public}d", width, height);
    }

    return nullptr;
}

napi_threadsafe_function registered_callback = nullptr;

struct data_buffer {
    char *buf;
    size_t size;
};

static void *terminal_worker(void *) {

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
                    } else {
                        hex += (char)buffer[i];
                    }
                }

                //  call callback registered by ArkTS
                if (hex.length() > 0 && registered_callback != nullptr) {
                    data_buffer *pbuf = new data_buffer{.buf = new char[hex.length()], .size = (size_t)hex.length()};
                    memcpy(pbuf->buf, &hex[0], hex.length());
                    napi_call_threadsafe_function(registered_callback, pbuf, napi_tsfn_nonblocking);
                }

                OH_LOG_INFO(LOG_APP, "Got: %{public}s", hex.c_str());
            } else if (r < 0) {

                OH_LOG_INFO(LOG_APP, "Program exited: %{public}ld %{public}d", r, errno);
            }
        }
    }
}

static napi_value run(napi_env env, napi_callback_info info) {

    size_t argc = 2;
    napi_value args[2] = {nullptr};

    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    napi_valuetype valuetype0;
    napi_typeof(env, args[0], &valuetype0);

    napi_valuetype valuetype1;
    napi_typeof(env, args[1], &valuetype1);

    double value0;
    napi_get_value_double(env, args[0], &value0);

    double value1;
    napi_get_value_double(env, args[1], &value1);

    int width = value0;
    int height = value1;

    if (fd < 0) {

        struct winsize ws = {};
        ws.ws_col = width;
        ws.ws_row = height;
        int pid = forkpty(&fd, nullptr, nullptr, &ws);

        if (!pid) {
            const char *home = "/storage/Users/currentUser";
            setenv("HOME", home, 1);
            setenv("PWD", home, 1);
            setenv("PATH", "/data/app/bin:/data/service/hnp/bin:/bin:/usr/local/bin:/usr/bin:/system/bin:/vendor/bin", 1);

            chdir(home);
            execl("/bin/sh", "/bin/sh", nullptr);
        }

        // set as non blocking
        int res = fcntl(fd, F_SETFL, fcntl(fd, F_GETFL) | O_NONBLOCK);
        assert(res == 0);

        // start terminal worker in another thread
        pthread_t terminal_thread;
        pthread_create(&terminal_thread, NULL, terminal_worker, nullptr);
    }

    return nullptr;
}

// send data to terminal
static napi_value send(napi_env env, napi_callback_info info) {

    size_t argc = 1;
    napi_value args[1] = {nullptr};
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    char *data;
    size_t length;
    napi_status ret = napi_get_arraybuffer_info(env, args[0], (void **)&data, &length);
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
    OH_LOG_INFO(LOG_APP, "Send: %{public}s", hex.c_str());

    if (fd > 0) {
        int written = 0;
        while (written < length) {
            int size = write(fd, (uint8_t *)data + written, length - written);
            assert(size >= 0);
            written += size;
        }
    }

    return nullptr;
}

void real_func_call_js(napi_env env, napi_value js_callback, void *context, void *data) {

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

static napi_value register_callback(napi_env env, napi_callback_info info) {

    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    napi_value src_cb_name;
    napi_create_string_utf8(env, "data_callback", NAPI_AUTO_LENGTH, &src_cb_name);

    napi_create_threadsafe_function(env, args[0], nullptr, src_cb_name, 0, 1, nullptr, nullptr, nullptr,
                                    real_func_call_js, &registered_callback);

    return nullptr;
}

EXTERN_C_START
static napi_value Init(napi_env env, napi_value exports) {
    napi_property_descriptor desc[] = {
        {"resize", nullptr, resize, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"run", nullptr, run, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"send", nullptr, send, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"subscribe", nullptr, register_callback, nullptr, nullptr, nullptr, napi_default, nullptr}};
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
