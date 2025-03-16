export const CONFIG = {
  APP_NAME: 'Avenir',
  API_URL: process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000/api',
  DEFAULT_LANGUAGE: 'ko',
} as const; 