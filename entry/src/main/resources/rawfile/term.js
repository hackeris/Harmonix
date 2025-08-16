hterm.Terminal.IO.prototype.sendString = function (data) {
    native.sendInput(data);
};
hterm.Terminal.IO.prototype.onVTKeystroke = function (data) {
    native.sendInput(data);
};
hterm.Terminal.IO.prototype.onTerminalResize = function (width, height) {
    native.resize(width, height);
};
hterm.ScrollPort.prototype.onTouch = function (e) {
    Object.defineProperty(e, 'defaultPrevented', { value: true });
};

hterm.defaultStorage = new lib.Storage.Memory();
window.onload = async function () {
    await lib.init();
    window.term = new hterm.Terminal();

    term.getPrefs().set('cursor-color', '#cccccc');
    term.getPrefs().set('terminal-encoding', 'iso-2022');
    term.getPrefs().set('enable-resize-status', false);
    term.getPrefs().set('copy-on-select', false);
    term.getPrefs().set('enable-clipboard-notice', false);
    term.getPrefs().set('screen-padding-size', 4);
    // Creating and preloading the <audio> element for this sometimes hangs WebKit on iOS 16 for some reason. Can be most easily reproduced by resetting a simulator and starting the app. System logs show Fig hanging while trying to do work.
    term.getPrefs().set('audible-bell-sound', '');

    term.onTerminalReady = onTerminalReady;
    term.decorate(document.getElementById('terminal'));
    term.installKeyboard();
};

function onTerminalReady() {

    // Functions for native -> JS
    window.exports = {};

    this.setCursorVisible(true);
    var io = term.io.push();
    term.reset();

    let decoder = new TextDecoder();
    exports.write = (data) => {
        term.io.writeUTF16(decoder.decode(lib.codec.stringToCodeUnitArray(data)));
    };

    // hterm size updates native size
    exports.getSize = () => [term.screenSize.width, term.screenSize.height];

    // selection, copying
    term.scrollPort_.screen_.contentEditable = false;
    term.blur();
    term.focus();
    exports.copy = () => term.copySelectionToClipboard();

    // focus
    // This listener blocks blur events that come in because the webview has lost first responder
    term.scrollPort_.screen_.addEventListener('blur', (e) => {
        if (e.target.ownerDocument.activeElement == e.target) {
            e.stopPropagation();
        }
    }, { capture: true });

    exports.setFocused = (focus) => {
        if (focus) {
            term.focus();
        } else {
            term.blur();
        }
    };
    // Scroll to bottom wrapper
    exports.scrollToBottom = () => term.scrollEnd();
    // Set scroll position
    exports.newScrollTop = (y) => {
        // two lines instead of one because the value you read out of scrollTop can be different from the value you write into it
        term.scrollPort_.screen_.scrollTop = y;
        lastScrollTop = term.scrollPort_.screen_.scrollTop;
    };

    exports.updateStyle = ({
        foregroundColor,
        backgroundColor,
        fontFamily,
        fontSize,
        colorPaletteOverrides,
        blinkCursor,
        cursorShape
    }) => {
        term.getPrefs().set('background-color', backgroundColor);
        term.getPrefs().set('foreground-color', foregroundColor);
        term.getPrefs().set('cursor-color', foregroundColor);
        term.getPrefs().set('font-family', fontFamily);
        term.getPrefs().set('font-size', fontSize);
        term.getPrefs().set('color-palette-overrides', colorPaletteOverrides);
        term.getPrefs().set('cursor-blink', blinkCursor);
        term.getPrefs().set('cursor-shape', cursorShape);
    };

    exports.getCharacterSize = () => {
        return [term.scrollPort_.characterSize.width, term.scrollPort_.characterSize.height];
    };

    exports.clearScrollback = () => term.clearScrollback();
    exports.setUserGesture = () => term.accessibilityReader_.hasUserGesture = true;

    hterm.openUrl = (url) => native.openLink(url);

    io.print('Welcome to Harmonix! A project to run Linux ELF binary on HarmonyOS.\r\n');
    io.print('Now ELF binary of aarch64 and x86_64 are supported (by qemu-harmonix-aarch64 \r\nand qemu-harmonix-x86_64).\r\n');
    io.print('\r\n');
    io.print(
        '     _   _                                  _      \r\n' +
        '    | | | | __ _ _ __ _ __ ___   ___  _ __ (_)_  __\r\n' +
        '    | |_| |/ _` | \'__| \'_ ` _ \\ / _ \\| \'_ \\| \\ \\/ /\r\n' +
        '    |  _  | (_| | |  | | | | | | (_) | | | | |>  < \r\n' +
        '    |_| |_|\\__,_|_|  |_| |_| |_|\\___/|_| |_|_/_/\\_\\\r\n'
    )
    io.print('\r\n');
    io.print('\r\n');
    io.print('To install or reinstall Alpine Linux, run `harmonix_install_alpine`.\r\n');
    io.print('To start Alpine Linux, run `harmonix_run_alpine`.\r\n');
    io.print('\r\n');
    io.print('You can also use Harmonix in HiShell. To uninstall from HiShell, run \r\n`harmonix_remove_alpine`\r\n');
    io.print('\r\n');
    io.print('To customize linux root filesystem or run x86_64, see harmonix_install_alpine \r\nand harmonix_run_alpine script.\r\n');

    native.load();
    native.syncFocus();
}
