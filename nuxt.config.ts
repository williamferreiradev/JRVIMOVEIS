import { join } from 'node:path'

// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  compatibilityDate: '2025-07-15',
  buildDir: join(process.cwd(), 'node_modules', '.cache', 'nuxt', '.nuxt'),
  devtools: { enabled: false },
  vite: {
    server: {
      watch: {
        ignored: ['**/.dev-logs/**'],
      },
    },
    optimizeDeps: {
      exclude: [
        '@supabase/supabase-js',
        '@supabase/auth-js',
        '@supabase/functions-js',
        '@supabase/realtime-js',
        '@supabase/storage-js',
        'lucide-vue-next',
        'swiper',
        'vue-draggable-plus',
      ],
    },
  },
  modules: ['@nuxtjs/tailwindcss', '@nuxtjs/supabase'],
  supabase: {
    useSsrCookies: true,
    redirect: true,
    redirectOptions: {
      login: '/login',
      callback: '/confirm',
      exclude: ['/catalogo', '/catalogo/**', '/_nuxt/**', '/favicon.ico'],
      saveRedirectToCookie: true,
    },
    cookieOptions: {
      maxAge: 60 * 60 * 8,
      sameSite: 'lax',
      secure: process.env.NODE_ENV === 'production',
    },
  },
  app: {
    head: {
      link: [
        {
          rel: 'preconnect',
          href: 'https://fonts.googleapis.com',
        },
        {
          rel: 'preconnect',
          href: 'https://fonts.gstatic.com',
          crossorigin: '',
        },
        {
          rel: 'stylesheet',
          href: 'https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&family=Playfair+Display:ital,wght@0,400;0,500;0,600;0,700;1,400;1,500;1,600;1,700&display=swap',
        },
      ],
    },
  },
})
