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
        'dark-text': '#1E1E1E',
        'datatable-hover': '#ECF2F7',
        'invalid-feedback': '#B9121C',
        'placeholder': '#9A9A9A',
        'gray-light': '#D9D9D9',
        'sort-asc': '#15FF10',
        'sort-desc': '#FF1010',
        'tab-link': '#8C8C8C',
        'tab-link-hover': '#3b3a3a',
        'input-border-main': '#979797',
        'input-light-border': '#bababa',
        'input-gray-border': '#565555',
        'button-main': '#9db9d3',
        'button-main-hover': '#7784b8',
        'button-main-disabled': '#b7c9db',
        'select-symbol': '#5B92D7',
        'table-head-bg': '#9DB9D3'
      },
      height: {
        0.5: '0.125rem',
        0.75: '0.1875rem'
      },
      margin: {
        30: '7.5rem'
      },
      spacing: {
        0.75: '0.1875rem'
      },
      width: {
        39: '9.375rem'
      },
      minWidth: {
        39: '9.375rem'
      },
      maxWidth: {
        39: '9.375rem'
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
