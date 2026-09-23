import type { Config } from 'tailwindcss'

export default <Partial<Config>>{
  content: [
    './components/**/*.{js,vue,ts}',
    './layouts/**/*.vue',
    './pages/**/*.vue',
    './plugins/**/*.{js,ts}',
    './app.vue',
    './error.vue'
  ],
  darkMode: 'class',
  theme: {
    extend: {
      fontFamily: {
        // Removendo Playfair para algo mais esportivo e corporativo (Inter para tudo)
        sans: ['Inter', 'system-ui', '-apple-system', 'sans-serif'],
        serif: ['Inter', 'Georgia', 'serif'],
        mono: ['IBM Plex Mono', 'ui-monospace', 'SFMono-Regular', 'monospace'],
      },
      colors: {
        primary: {
          DEFAULT: '#0A3D8F', // Azul Royal JRV Imóveis
          50: '#F0F5FF',
          100: '#E1ECFE',
          200: '#C7DAFE',
          300: '#9DBEFC',
          400: '#6999F7',
          500: '#0A3D8F',
          600: '#083276',
          700: '#06265D',
          800: '#041B44',
          900: '#02102C',
          glow: 'rgba(10, 61, 143, 0.25)'
        },
        dark: {
          bg: '#0B132B',       // Fundo Dark Azul Marinho Nobre
          surface: '#111C3D',  // Superfícies secundárias
          card: '#16234D',     // Cards e painéis
          border: '#23356D',   // Bordas e divisores
          text: '#F8FAFC',     // Texto principal
          muted: '#94A3B8'     // Texto secundário
        },
        accent: {
          DEFAULT: '#C8A261',  // Dourado Champagne JRV
          50: '#FAF7F0',
          100: '#F4EEDB',
          200: '#E9DCB8',
          300: '#DEC994',
          400: '#D3B671',
          500: '#C8A261',
          600: '#B08A46',
          700: '#8C6C32',
          800: '#684F22',
          900: '#463414',
          glow: 'rgba(200, 162, 97, 0.25)'
        }
      },
      boxShadow: {
        luxury: '0 10px 30px -5px rgba(10, 61, 143, 0.25)',
        gold: '0 10px 25px -5px rgba(200, 162, 97, 0.25)',
        card: '0 1px 3px 0 rgba(0, 0, 0, 0.1), 0 1px 2px -1px rgba(0, 0, 0, 0.06)',
        'card-hover': '0 10px 20px -3px rgba(10, 61, 143, 0.15), 0 4px 6px -4px rgba(0, 0, 0, 0.1)',
      },
      borderRadius: {
        card: '8px',
      }
    }
  }
}
