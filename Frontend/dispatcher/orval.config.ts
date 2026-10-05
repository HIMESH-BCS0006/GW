import { defineConfig } from 'orval';

export default defineConfig({
  waypoint: {
    input: {
      target: './docs/openapi.yaml',
    },
    output: {
      mode: 'tags-split',
      target: './src/api/generated',
      schemas: './src/api/generated/models',
      client: 'react-query',
      override: {
        mutator: {
          path: './src/api/http.ts',
          name: 'customInstance',
        },
      },
    },
  },
});
