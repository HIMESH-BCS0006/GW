// src/global.d.ts
/** Tell TypeScript that any imported *.css file is a side‑effect‑only module. */
declare module '*.css' {
  // The module has no exports – the import is only for its side effects.
  const _: any;
  export default _;
}