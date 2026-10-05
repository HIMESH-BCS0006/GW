module.exports = {
  root: true,
  env: {
    browser: true,
    es2022: true,
    node: true,
  },
  parser: '@typescript-eslint/parser',
  parserOptions: {
    ecmaVersion: 2022,
    sourceType: 'module',
    project: ['./tsconfig.json'],
  },
  plugins: ['@typescript-eslint', 'react'],
  extends: [
    'eslint:recommended',
    'plugin:@typescript-eslint/recommended',
    'plugin:react/recommended',
    'plugin:react/jsx-runtime',
  ],
  settings: {
    react: { version: 'detect' },
  },
  // Disable noisy rules globally
  rules: {
    '@typescript-eslint/no-explicit-any': 'off',
    '@typescript-eslint/no-unused-vars': 'off',
    '@typescript-eslint/ban-ts-comment': 'off',
    'no-irregular-whitespace': 'off',
  },
  // Ignore build artefacts and non‑TS config files that cause parsing errors
  ignorePatterns: [
    'dist/',
    'node_modules/',
    'postcss.config.js',
    'tailwind.config.js',
    'vite.config.ts',
    'orval.config.ts',
  ],
  overrides: [
    // Turn off strict TS rules for generated code and test files
    {
      files: ['src/api/generated/**/*.ts', '**/*.test.*', '**/*.test.tsx'],
      rules: {
        '@typescript-eslint/no-explicit-any': 'off',
        '@typescript-eslint/no-unused-vars': 'off',
        '@typescript-eslint/ban-ts-comment': 'off',
      },
    },
    // Use the default JS parser for plain config files so they aren't type‑checked
    {
      files: ['*.js', '*.cjs', '*.mjs'],
      parser: 'espree',
      parserOptions: { sourceType: 'module' },
      rules: {
        '@typescript-eslint/no-explicit-any': 'off',
        '@typescript-eslint/no-unused-vars': 'off',
      },
    },
  ],
};
