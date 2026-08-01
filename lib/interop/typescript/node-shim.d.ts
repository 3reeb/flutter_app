declare module 'fs' {
  const fs: any;
  export default fs;
  export const mkdirSync: any;
  export const existsSync: any;
  export const writeFileSync: any;
}
declare module 'path' {
  const path: any;
  export default path;
}
declare const process: any;
declare const console: any;
