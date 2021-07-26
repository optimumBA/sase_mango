module.exports = {
  mode: 'jit',
  purge: {
    content: [
      './js/**/*.js',
      '../lib/sase_mango_web/live/**/*.*',
      '../lib/sase_mango_web/templates/**/*.*',
      '../lib/sase_mango_web/views/**/*.*',
    ],
  },
  darkMode: false,
  plugins: [],
}
