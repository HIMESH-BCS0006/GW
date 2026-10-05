// /// <reference types="vitest" />
// import { defineConfig } from 'vite';
// import react from '@vitejs/plugin-react';
// import path from 'path';




// // export default defineConfig({
// //   plugins: [react()],
// //   resolve: {
// //     alias: {
// //       '@': path.resolve(__dirname, './src'),
// //     },
// //   },
// //   test: {
// //     globals: true,
// //     environment: 'jsdom',
// //     setupFiles: './src/test/setup.ts',
// //   },
// // });
// // https://vitejs.dev
// export default defineConfig({
//   plugins: [react()],
//   server: {
//     proxy: {
//       '/api': {
//         target: 'http://localhost:5000',
//         changeOrigin: true,
//         secure: false,
//       },
//     },
//   },
// })
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import path from "path";

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "./src"),
    },
  },
});