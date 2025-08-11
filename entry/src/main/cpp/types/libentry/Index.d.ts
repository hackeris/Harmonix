export const run: (w: number, h: number) => void;
export const send: (content: ArrayBuffer) => void;
export const subscribe: (cb: (ArrayBuffer) => void) => void;
export const resize: (w: number, h: number) => void;