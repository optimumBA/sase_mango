const defaultTheme = require('tailwindcss/defaultTheme')

module.exports = {
  content: ['./js/**/*.js', '../lib/*_web.ex', '../lib/*_web/**/*.*ex'],
  theme: {
    extend: {
      animation: {
        'show-tab-line': 'show-tab-line 0.4s ease-in-out forwards',
        'show-table-rows': 'show-table-rows 0.6s ease-in-out',
      },
      colors: {
        blue: {
          'dark': {
            100: "#b7c9db",
            200: "#9DB9D3",
            500: "#5B92D7"
          },
        },
        violet: {
          'dark': {
            350: "#7784b8"
          }
        },
        green: {
          350: "#15FF10"
        },
        gray: {
          350: "#D9D9D9",
          450: "#8C8C8C",
          750: "#3b3a3a",
        },
        red: {
          550: "#FF1010"
        },
      },
      height: {
        0.5: '0.125rem',
        0.75: '0.1875rem',
        95: '23.75rem',
        94: '23.5rem',
      },
      margin: {
        30: '7.5rem'
      },
      spacing: {
        0.75: '0.1875rem'
      },
      width: {
        39: '9.375rem',
        95: '23.75rem'
      },
      minWidth: {
        39: '9.375rem'
      },
      maxWidth: {
        39: '9.375rem',
        94: '23.5rem',
      },
      maxHeight: {
        94: '23.5rem',
      },
      fontFamily: {
        montserrat: ['Montserrat', ...defaultTheme.fontFamily.sans],
        inter: ['Inter', ...defaultTheme.fontFamily.sans],
      },
      screens: {
        'md-2': '850px',
      }
    },
  },
  plugins: [require('@tailwindcss/forms')],
}
