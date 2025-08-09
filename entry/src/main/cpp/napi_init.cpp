#include "napi/native_api.h"
#include <algorithm>
#include <array>
#include <assert.h>
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

static int width = 127;
static int height = 36;

static int fd = -1;

static napi_value Add(napi_env env, napi_callback_info info) {
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

    napi_value sum;
    napi_create_double(env, value0 + value1, &sum);

    return sum;
}

static void *terminal_worker(void *) {}

static napi_value Run(napi_env env, napi_callback_info info) {

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

    width = value0;
    height = value1;

    if (!fd) {
        struct winsize ws = {};
        ws.ws_col = width;
        ws.ws_row = height;
        int pid = forkpty(&fd, nullptr, nullptr, &ws);

        if (!pid) {
            const char *home = "/storage/Users/currentUser";
            setenv("HOME", home, 1);
            setenv("PWD", home, 1);

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

    void *data;
    size_t length;
    napi_status ret = napi_get_arraybuffer_info(env, args[0], &data, &length);
    assert(ret == napi_ok);

//    SendData((uint8_t *)data, length);
    return nullptr;
}

EXTERN_C_START
static napi_value Init(napi_env env, napi_value exports) {
    napi_property_descriptor desc[] = {{"add", nullptr, Add, nullptr, nullptr, nullptr, napi_default, nullptr},
                                       {"run", nullptr, Run, nullptr, nullptr, nullptr, napi_default, nullptr},
                                       {"send", nullptr, send, nullptr, nullptr, nullptr, napi_default, nullptr}};
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
