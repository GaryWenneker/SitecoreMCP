import js from '@eslint/js';
import tseslint from 'typescript-eslint';
import prettierConfig from 'eslint-config-prettier';

export default [
  js.configs.recommended,
  ...tseslint.configs.recommended,
  prettierConfig,
  {
    files: ['src/**/*.ts'],
    languageOptions: {
      ecmaVersion: 2022,
      sourceType: 'module',
      parserOptions: {
        project: './tsconfig.json',
      },
    },
    rules: {
      '@typescript-eslint/no-explicit-any': 'off', // Allow any for MCP flexibility
      '@typescript-eslint/explicit-function-return-type': 'off',
      '@typescript-eslint/no-unused-vars': [
        'warn', // Changed from error to warn
        {
          argsIgnorePattern: '^_',
          varsIgnorePattern: '^_',
          caughtErrorsIgnorePattern: '^_', // Ignore caught errors starting with _
        },
      ],
      'no-console': 'off', // Console is used for MCP stderr output
      'prefer-const': 'warn', // Changed from error to warn
      'no-var': 'error',
      'no-case-declarations': 'warn', // Changed from error to warn
      'no-useless-escape': 'off', // Allow escapes in regex/GraphQL strings
    },
  },
  {
    ignores: ['dist/', 'node_modules/', '**/*.js', '**/*.cjs', '**/*.d.ts'],
  },
];
