export const run: (id: number, w: number, h: number, dcb: (ArrayBuffer) => void, ecb: () => void) => void;
export const send: (id: number, content: ArrayBuffer) => void;
export const resize: (id: number, w: number, h: number) => void;
export const close: (id: number) => void;